import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = PurchaseService.shared
    @State private var selected: TetherProduct = Catalog.annualProduct
    @State private var showRestored = false

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
            .background(TetherColor.bg)
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

    private var options: some View {
        VStack(spacing: TetherSpace.m) {
            ForEach(Catalog.products) { product in
                Button {
                    selected = product
                } label: {
                    HStack(spacing: TetherSpace.m) {
                        Image(systemName: selected == product ? "largecircle.fill.circle" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(selected == product ? TetherColor.brand : TetherColor.border)

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
                            Text(product.detail)
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
                    .background(selected == product ? TetherColor.tint : TetherColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: TetherRadius.medium)
                            .strokeBorder(selected == product ? TetherColor.brand : TetherColor.border,
                                          lineWidth: selected == product ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(product.title), \(product.priceLabel)")
                .accessibilityAddTraits(selected == product ? [.isSelected] : [])
            }
        }
    }

    private var cta: some View {
        VStack(spacing: TetherSpace.m) {
            Button {
                Task {
                    if store.entitlement.isPaid {
                        dismiss()
                    } else {
                        await store.purchase(selected)
                        dismiss()
                    }
                }
            } label: {
                if store.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Start \(TrialConfig.label)")
                }
            }
            .tetherButton()
            .disabled(store.isLoading)

            Text("Then \(selected.priceLabel). Cancel anytime in Settings.")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Button("Restore purchases") {
                Task {
                    await store.restore()
                    showRestored = true
                }
            }
            .font(TetherType.caption)
            .foregroundStyle(TetherColor.brand)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            Text("Subscriptions renew automatically unless cancelled at least 24 hours before the period ends. Manage in your App Store account.")
                .font(.system(size: 11))
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)
            Text("Tether is not therapy and not a crisis service.")
                .font(.system(size: 11))
                .foregroundStyle(TetherColor.muted)
        }
        .padding(.top, TetherSpace.s)
    }
}
