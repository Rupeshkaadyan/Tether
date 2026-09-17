import Foundation
import Observation

// MARK: - Entitlement

enum Entitlement: String, Codable {
    case free, premium, couplesPlus

    var isPaid: Bool { self != .free }

    var displayName: String {
        switch self {
        case .free:        return "Free"
        case .premium:     return "Premium"
        case .couplesPlus: return "Couples+"
        }
    }
}

// MARK: - Products

struct TetherProduct: Identifiable, Hashable {
    let id: String
    let title: String
    let priceLabel: String
    let detail: String
    let isAnnual: Bool
    let badge: String?
}

enum Catalog {
    /// Store identifiers — must match App Store Connect exactly.
    static let monthly    = "app.tether.premium.monthly"
    static let annual     = "app.tether.premium.annual"
    static let couplesPlus = "app.tether.couplesplus.annual"

    static let products: [TetherProduct] = [
        TetherProduct(id: annual,
                      title: "Yearly",
                      priceLabel: "$79.99 / year",
                      detail: "About $6.67 a month",
                      isAnnual: true,
                      badge: "Best value"),
        TetherProduct(id: monthly,
                      title: "Monthly",
                      priceLabel: "$12.99 / month",
                      detail: "Cancel anytime",
                      isAnnual: false,
                      badge: nil),
        TetherProduct(id: couplesPlus,
                      title: "Couples+",
                      priceLabel: "$149.99 / year",
                      detail: "Everything, plus two live sessions with a coach",
                      isAnnual: true,
                      badge: nil)
    ]

    static let annualProduct = products[0]
}

// MARK: - Trial

enum TrialConfig {
    /// Currently 3 days, per the brief.
    ///
    /// Flagged concern: in a two-person app the trial can expire before the
    /// partner has even installed it. The category standard is 7 days, and one
    /// competitor publicly notes that 7 is "standard rather than generous".
    /// 14 days was the recommendation in the PRD. Changing this is a one-line edit.
    static let days = 3

    static var label: String { "\(days)-day free trial" }
}

// MARK: - Service

@Observable
final class PurchaseService {

    static let shared = PurchaseService()

    private let entitlementKey = "tether.entitlement"
    private let trialStartKey  = "tether.trialStart"

    var entitlement: Entitlement = .free
    var isInTrial = false
    var trialDaysRemaining = 0
    var isLoading = false
    var lastError: String?

    private init() { load() }

    // MARK: Derived

    var hasAccess: Bool { entitlement.isPaid }

    var trialExpired: Bool {
        guard let start = UserDefaults.standard.object(forKey: trialStartKey) as? Date else {
            return false
        }
        return Date().timeIntervalSince(start) > Double(TrialConfig.days) * 86_400
    }

    var statusLabel: String {
        if entitlement.isPaid { return entitlement.displayName }
        if isInTrial { return "Trial · \(trialDaysRemaining) day\(trialDaysRemaining == 1 ? "" : "s") left" }
        if trialExpired { return "Trial ended" }
        return "Free"
    }

    // MARK: Actions

    /// Begins the introductory trial. Called the first time the paywall is
    /// dismissed with a trial-aware CTA, never automatically on install.
    func startTrial() {
        guard UserDefaults.standard.object(forKey: trialStartKey) == nil else { return }
        UserDefaults.standard.set(Date(), forKey: trialStartKey)
        refresh()
    }

    func purchase(_ product: TetherProduct) async {
        isLoading = true
        defer { isLoading = false }
        try? await Task.sleep(nanoseconds: 700_000_000)

        entitlement = product.id == Catalog.couplesPlus ? .couplesPlus : .premium
        persist()
        refresh()
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        try? await Task.sleep(nanoseconds: 500_000_000)
        load()
    }

    func refresh() {
        isInTrial = entitlement == .free && hasActiveTrial
        trialDaysRemaining = max(0, TrialConfig.days - daysSinceTrialStart)
    }

    private var hasActiveTrial: Bool {
        guard let start = UserDefaults.standard.object(forKey: trialStartKey) as? Date else { return false }
        return Date().timeIntervalSince(start) <= Double(TrialConfig.days) * 86_400
    }

    private var daysSinceTrialStart: Int {
        guard let start = UserDefaults.standard.object(forKey: trialStartKey) as? Date else { return 0 }
        return Int(Date().timeIntervalSince(start) / 86_400)
    }

    // MARK: Persistence

    private func persist() {
        UserDefaults.standard.set(entitlement.rawValue, forKey: entitlementKey)
    }

    private func load() {
        let raw = UserDefaults.standard.string(forKey: entitlementKey) ?? Entitlement.free.rawValue
        entitlement = Entitlement(rawValue: raw) ?? .free
        refresh()
    }

    /// Local stand-in. When the RevenueCat SDK is added, only this class changes:
    /// `purchase` becomes `Purchases.shared.purchase(product:)`, `restore`
    /// becomes `Purchases.shared.restorePurchases()`, and `refresh` reads
    /// `CustomerInfo.entitlements`. Every view keeps its current shape.
    func note() -> String {
        "Purchases are simulated locally. RevenueCat is not yet connected."
    }
}
