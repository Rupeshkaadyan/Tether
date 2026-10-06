import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = PurchaseService.shared
    @State private var selectedID: String = Catalog.annual
    @State private var showRestored = false
    @State private var restoreFoundNothing = false

    /// The product the person has chosen, once StoreKit has loaded it.
    private var selected: TetherProduct? {
        store.products.first { $0.id == selectedID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.xl) {
                    headline
                    sharedLine
                    features
                    options
                    cta
                    footer
                }
                .padding(TetherSpace.margin)
            }
            .background { TetherBackdrop() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
            }
            .alert("Purchases restored", isPresented: $showRestored) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("If you had a subscription, it is active again.")
            }
            .alert("Nothing to restore", isPresented: $restoreFoundNothing) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("No previous subscription was found for this Apple Account.")
            }
            .task {
                // A paywall opened before the products finished loading shows a
                // loading state rather than an empty list or an invented price.
                if !store.productsLoaded { await store.loadProducts() }
            }
        }
    }

    // MARK: - Sections

    private var headline: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            Text("Keep the practice going")
                .font(TetherType.display)
                .foregroundStyle(TetherColor.ink)
            Text("Everything in Tether, for both of you, for less than one takeaway a month.")
                .font(TetherType.callout)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, TetherSpace.l)
    }

    private var sharedLine: some View {
        HStack(spacing: TetherSpace.s) {
            Image(systemName: "person.2.fill")
                .accessibilityHidden(true)
                .font(.system(size: 14))
            Text("One subscription. Both partners. Always.")
                .font(TetherType.label)
        }
        .foregroundStyle(TetherColor.ink)
        .padding(TetherSpace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TetherColor.tint)
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            feature("bubble.left.and.text.bubble.right", "A daily prompt", "One question a day. Under a minute.")
            feature("brain.head.profile", "The full coach", "Remembers what you have written. Voice included.")
            feature("book.closed", "Your wisdom track", "Every track, and every update to it.")
            feature("chart.line.uptrend.xyaxis", "Relationship Pulse", "A weekly read on how you are doing.")
            feature("lock.shield", "End-to-end encrypted", "We cannot read your entries. Ever.")
        }
    }

    private func feature(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: TetherSpace.m) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(TetherColor.brand)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TetherType.label)
                    .foregroundStyle(TetherColor.text)
                Text(detail)
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var options: some View {
        if !store.productsLoaded {
            HStack(spacing: TetherSpace.s) {
                ProgressView()
                Text("Loading subscriptions…")
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(TetherSpace.m)
        } else {
            VStack(spacing: TetherSpace.m) {
                ForEach(store.products) { product in
                    optionRow(product)
                }
            }
        }
    }

    private func optionRow(_ product: TetherProduct) -> some View {
        Button {
            selectedID = product.id
        } label: {
            HStack(spacing: TetherSpace.m) {
                Image(systemName: selectedID == product.id
                      ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selectedID == product.id
                                     ? TetherColor.brand : TetherColor.border)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: TetherSpace.s) {
                        Text(product.title)
                            .font(TetherType.label)
                            .foregroundStyle(TetherColor.text)
                        if let badge = product.badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(TetherColor.thriving)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(TetherColor.thriving.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    // The trial length comes from the subscription itself, so
                    // it cannot promise something the offer does not include.
                    Text(product.introLabel ?? product.detail)
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                }

                Spacer(minLength: 0)

                Text(product.priceLabel)
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.text)
                    .multilineTextAlignment(.trailing)
            }
            .padding(TetherSpace.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selectedID == product.id ? TetherColor.tint : TetherColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: TetherRadius.medium)
                    .strokeBorder(selectedID == product.id
                                  ? TetherColor.brand : TetherColor.border,
                                  lineWidth: selectedID == product.id ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!product.isAvailable)
        .opacity(product.isAvailable ? 1 : 0.5)
        .accessibilityLabel("\(product.title), \(product.priceLabel)")
        .accessibilityAddTraits(selectedID == product.id ? [.isSelected] : [])
    }

    private var cta: some View {
        VStack(spacing: TetherSpace.m) {
            Button {
                Task {
                    if store.hasAccess {
                        dismiss()
                    } else if let selected {
                        let ok = await store.purchase(selected)
                        if ok { dismiss() }
                    }
                }
            } label: {
                if store.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(ctaLabel)
                }
            }
            .tetherButton()
            .disabled(store.isLoading || !(selected?.isAvailable ?? false))

            if let error = store.lastError {
                Text(error)
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.strained)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Restore purchases") {
                Task {
                    await store.restore()
                    if store.hasAccess { showRestored = true }
                    else { restoreFoundNothing = true }
                }
            }
            .font(TetherType.caption)
            .foregroundStyle(TetherColor.brand)
        }
    }

    /// Names the trial only when StoreKit says there is one.
    private var ctaLabel: String {
        if store.hasAccess { return "Continue" }
        if let intro = selected?.introLabel { return "Start \(intro)" }
        return "Subscribe"
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            Text(Legal.renewalDisclosure)
                .font(.system(size: 11))
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: TetherSpace.m) {
                Link("Privacy policy", destination: Legal.privacyPolicy)
                Link("Terms", destination: Legal.subscriptionTerms)
                Link("Manage", destination: Legal.manageSubscriptions)
            }
            .font(.system(size: 11))

            Text("Tether is not therapy and not a crisis service.")
                .font(.system(size: 11))
                .foregroundStyle(TetherColor.muted)
        }
        .padding(.top, TetherSpace.s)
    }
}
