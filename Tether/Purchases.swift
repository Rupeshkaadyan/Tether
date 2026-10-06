import Foundation
import Observation
import StoreKit

// MARK: - Entitlement

enum Entitlement: String, Codable {
    case free, premium

    var isPaid: Bool { self != .free }

    var displayName: String {
        switch self {
        case .free:    return "Free"
        case .premium: return "Premium"
        }
    }
}

// MARK: - Products
//
// Prices are NOT stored here any more.
//
// They used to be hard-coded ("$79.99 / year"). A price the app invents can
// disagree with the price in App Store Connect, and Apple treats that as
// inaccurate metadata — the number a person is shown must be the number
// StoreKit will charge. `displayPrice` comes from the store, in the store's
// currency and format, so it is correct by construction.

struct TetherProduct: Identifiable, Hashable {
    let id: String
    /// Product metadata that is presentation, not price.
    let fallbackTitle: String
    let detail: String
    let isAnnual: Bool
    let badge: String?
    /// nil until StoreKit has loaded. The UI shows a loading state, not a guess.
    var storeProduct: Product?

    var title: String { storeProduct?.displayName ?? fallbackTitle }
    var priceLabel: String { storeProduct?.displayPrice ?? "—" }
    var isAvailable: Bool { storeProduct != nil }

    /// The free trial Apple will actually honour, if the subscription has one.
    var introOffer: Product.SubscriptionOffer? {
        storeProduct?.subscription?.introductoryOffer
    }

    var hasIntroOffer: Bool { introOffer != nil }

    /// e.g. "7-day free trial", or nil when there is no offer.
    var introLabel: String? {
        guard let offer = introOffer else { return nil }
        let unit: String
        switch offer.period.unit {
        case .day:   unit = offer.period.value == 1 ? "day" : "days"
        case .week:  unit = offer.period.value == 1 ? "week" : "weeks"
        case .month: unit = offer.period.value == 1 ? "month" : "months"
        case .year:  unit = offer.period.value == 1 ? "year" : "years"
        @unknown default: unit = "days"
        }
        return "\(offer.period.value)-\(unit) free trial"
    }

    static func == (lhs: TetherProduct, rhs: TetherProduct) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum Catalog {
    /// Store identifiers — must match App Store Connect exactly.
    ///
    /// Couples+ was removed: it promised "two live sessions with a coach"
    /// inside an in-app purchase. A subscription has to deliver what it says
    /// it delivers, and a human coaching service is a commitment this app
    /// cannot currently keep. Re-add it only alongside real delivery.
    static let monthly = "app.tether.premium.monthly"
    static let annual  = "app.tether.premium.annual"

    static let ids = [annual, monthly]

    static var products: [TetherProduct] {
        [
            TetherProduct(id: annual,
                          fallbackTitle: "Yearly",
                          detail: "One payment a year",
                          isAnnual: true,
                          badge: "Best value"),
            TetherProduct(id: monthly,
                          fallbackTitle: "Monthly",
                          detail: "Cancel anytime",
                          isAnnual: false,
                          badge: nil)
        ]
    }
}

// MARK: - Service

/// Real StoreKit 2.
///
/// This replaces a local simulation that slept for 700ms and then set the
/// entitlement itself. That would have been rejected — unlocking paid features
/// without In-App Purchase is a hard guideline violation — and worse, it would
/// have taught the app to trust a flag it wrote to UserDefaults, which any
/// device restore or reinstall would have to be re-earned anyway.
///
/// Entitlement is now derived from StoreKit's own verified transactions. There
/// is no local flag to forge, and renewals, refunds and family sharing all
/// arrive through `Transaction.updates`.
@Observable
final class PurchaseService {

    static let shared = PurchaseService()

    var products: [TetherProduct] = Catalog.products
    var entitlement: Entitlement = .free
    var isLoading = false
    var productsLoaded = false
    var lastError: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        // Renewals, refunds and purchases made on another device all arrive
        // here. Started once, for the lifetime of the app.
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self.refreshEntitlement()
                }
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlement()
        }
    }

    // MARK: Derived

    var hasAccess: Bool { entitlement.isPaid }

    var statusLabel: String { entitlement.displayName }

    var canPurchase: Bool { products.contains { $0.isAvailable } }

    // MARK: Loading

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Catalog.ids)
            products = Catalog.products.map { base in
                var copy = base
                copy.storeProduct = loaded.first { $0.id == base.id }
                return copy
            }
            productsLoaded = true
            if loaded.isEmpty {
                // Products exist in code but not in App Store Connect yet, or
                // the paid agreements are unsigned. Say so rather than showing
                // a button that cannot work.
                lastError = "Subscriptions are not available yet."
            }
        } catch {
            lastError = "Could not reach the App Store."
        }
    }

    // MARK: Purchasing

    /// Returns true when the person now has access.
    @discardableResult
    func purchase(_ product: TetherProduct) async -> Bool {
        guard let storeProduct = product.storeProduct else {
            lastError = "That subscription is not available yet."
            return false
        }

        isLoading = true
        defer { isLoading = false }
        lastError = nil

        do {
            switch try await storeProduct.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    lastError = "That purchase could not be verified."
                    return false
                }
                await transaction.finish()
                await refreshEntitlement()
                return hasAccess

            case .userCancelled:
                return false

            case .pending:
                // Ask-to-Buy, or a bank check. Not an error, and not a failure
                // to report as one.
                lastError = "Waiting for approval. This unlocks once it is approved."
                return false

            @unknown default:
                return false
            }
        } catch {
            lastError = "The purchase could not be completed."
            return false
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        lastError = nil
        // Prompts for the App Store account, then re-reads entitlements.
        try? await AppStore.sync()
        await refreshEntitlement()
        if !hasAccess {
            lastError = "No previous subscription was found."
        }
    }

    /// The only place entitlement is decided.
    func refreshEntitlement() async {
        var paid = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate == nil,
               Catalog.ids.contains(transaction.productID) {
                paid = true
            }
        }
        entitlement = paid ? .premium : .free
    }
}
