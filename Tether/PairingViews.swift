import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins
import UIKit

// MARK: - QR helper

enum QRCode {
    static func image(from string: String, size: CGFloat = 190) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale = size / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: - Root

struct PairingView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var invite: Invite?
    @State private var showRedeem = false
    @State private var justPaired = false

    var body: some View {
        NavigationStack {
            Group {
                if justPaired {
                    PairingSuccessView(partnerName: partner?.displayName ?? "your partner") {
                        dismiss()
                    }
                } else if let invite {
                    WaitingRoomView(invite: invite, profile: profile) {
                        justPaired = true
                    } onSolo: {
                        dismiss()
                    } onRedeem: {
                        showRedeem = true
                    }
                } else {
                    InviteMethodsView {
                        invite = PairingService.createInvite(in: ctx, inviterID: profile.id)
                    } onRedeem: {
                        showRedeem = true
                    }
                }
            }
            .navigationTitle("Invite your partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showRedeem) {
                RedeemCodeView(profile: profile) {
                    showRedeem = false
                    justPaired = true
                }
            }
            .task {
                if invite == nil {
                    invite = PairingService.pendingInvite(in: ctx, inviterID: profile.id)
                }
                if profile.partnerID != nil { justPaired = true }
            }
        }
    }

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        let all = (try? ctx.fetch(FetchDescriptor<UserProfile>())) ?? []
        return all.first { $0.id == id }
    }
}

// MARK: - Invite methods

struct InviteMethodsView: View {
    let onCreate: () -> Void
    let onRedeem: () -> Void

    @State private var selectedID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TetherSpace.l) {
                Text("Three ways to connect")
                    .font(TetherType.title)
                    .foregroundStyle(TetherColor.ink)
                    .padding(.top, TetherSpace.l)

                Text("Pick whichever is easiest. Tap a different one any time to change your mind.")
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.muted)

                ForEach(methods) { method in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedID = method.id
                        }
                        TetherHaptics.light()
                    } label: {
                        HStack(alignment: .top, spacing: TetherSpace.m) {
                            Image(systemName: method.symbol)
                                .font(.system(size: 18))
                                .foregroundStyle(TetherColor.brand)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: TetherSpace.xs) {
                                Text(method.title)
                                    .font(TetherType.label)
                                Text(method.detail)
                                    .font(TetherType.caption)
                                    .foregroundStyle(TetherColor.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                            if selectedID == method.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(TetherColor.brand)
                            }
                        }
                        .padding(TetherSpace.l)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selectedID == method.id ? TetherColor.brandSoft : TetherColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous)
                                .strokeBorder(selectedID == method.id ? TetherColor.brand : TetherColor.border,
                                              lineWidth: selectedID == method.id ? 2 : 1)
                        )
                        .tetherShadow(selectedID == method.id ? .lifted : .soft)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedID == method.id ? [.isSelected] : [])
                }

                Button {
                    TetherHaptics.success()
                    onCreate()
                } label: {
                    Text(selectedID == nil ? "Create my invite" : "Continue")
                }
                .tetherButton()
                .padding(.top, TetherSpace.s)
                .disabled(selectedID == nil)
                .opacity(selectedID == nil ? 0.5 : 1)

                Button("I have a code") { onRedeem() }
                    .tetherButton(.tertiary)

                Text("You can start on your own at any point. Nothing is lost when they join later.")
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
                    .padding(.top, TetherSpace.s)
            }
            .padding(TetherSpace.margin)
        }
        .background(TetherColor.bg)
    }

    private let methods = [
        Method(id: "link", symbol: "link", title: "Send a link",
               detail: "Send over iMessage or WhatsApp. Works even if they have not installed it yet."),
        Method(id: "qrcode", symbol: "qrcode", title: "Scan in person",
               detail: "Sit together and scan. This one always works, no network needed."),
        Method(id: "number", symbol: "number", title: "Share a 6-digit code",
               detail: "They type it in. Good for phone calls or when links get eaten by an app.")
    ]

    private struct Method: Identifiable {
        let id: String
        let symbol: String
        let title: String
        let detail: String
    }
}

// MARK: - Waiting room

struct WaitingRoomView: View {
    @Bindable var invite: Invite
    @Bindable var profile: UserProfile

    let onPaired: () -> Void
    let onSolo: () -> Void
    let onRedeem: () -> Void

    @Environment(\.modelContext) private var ctx
    @State private var showCopied = false
    @State private var tick = 0

    private var qrPayload: String {
        "tether://join?code=\(invite.code)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TetherSpace.l) {

                statusHeader

                if let image = QRCode.image(from: qrPayload) {
                    VStack(spacing: TetherSpace.m) {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 190, height: 190)
                            .padding(TetherSpace.m)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: TetherRadius.medium)
                                    .strokeBorder(TetherColor.border, lineWidth: 1)
                            )
                        Text("Scan this on their phone")
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                    }
                    .frame(maxWidth: .infinity)
                }

                codeBlock

                messageBlock

                if invite.canNudge {
                    Button("Send a reminder") {
                        PairingService.nudge(invite, in: ctx)
                    }
                    .tetherButton(.secondary)
                }

                if invite.shouldOfferSolo {
                    soloFallback
                }

                Button("Continue on my own", action: onSolo)
                    .tetherButton(.tertiary)

                Button("Enter their code instead") { onRedeem() }
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.brand)
                    .frame(maxWidth: .infinity)

                Text("Invite expires in 7 days. You can cancel and make a new one anytime.")
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
                    .padding(.bottom, TetherSpace.xl)
            }
            .padding(TetherSpace.margin)
        }
        .background(TetherColor.bg)
    }

    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: TetherSpace.xs) {
            HStack(spacing: TetherSpace.s) {
                Circle()
                    .fill(TetherColor.drifting)
                    .frame(width: 8, height: 8)
                Text("Waiting for your partner")
                    .font(TetherType.headline)
                    .foregroundStyle(TetherColor.text)
            }
            Text(PairingService.elapsedLabel(for: invite))
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
        }
        .padding(.top, TetherSpace.l)
    }

    private var codeBlock: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                Text("Or share this code")
                    .font(TetherType.label)
                HStack {
                    Text(invite.code)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(TetherColor.ink)
                        .accessibilityLabel("Invite code \(invite.code)")
                    Spacer()
                    Button {
                        UIPasteboard.general.string = invite.code
                        showCopied = true
                    } label: {
                        Label(showCopied ? "Copied" : "Copy",
                              systemImage: showCopied ? "checkmark" : "doc.on.doc")
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.brand)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var messageBlock: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                Text("Not sure what to say? Send this:")
                    .font(TetherType.label)
                Text(PairingService.inviteMessage)
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.text)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    UIPasteboard.general.string = PairingService.inviteMessage
                    showCopied = true
                } label: {
                    Label(showCopied ? "Copied" : "Copy message",
                          systemImage: showCopied ? "checkmark" : "doc.on.doc")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.brand)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var soloFallback: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                Label("Start on your own", systemImage: "arrow.right")
                    .font(TetherType.label)
                    .foregroundStyle(TetherColor.ink)
                Text("It has been three days. You do not have to wait — everything you write syncs the moment they join.")
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Begin solo", action: onSolo)
                    .tetherButton()
                    .padding(.top, TetherSpace.xs)
            }
            .padding(TetherSpace.l)
            .background(TetherColor.tint)
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium))
        }
    }
}

// MARK: - Redeem

struct RedeemCodeView: View {
    @Bindable var profile: UserProfile
    let onPaired: () -> Void

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var name = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.l) {
                    Text("Enter their code")
                        .font(TetherType.title)
                        .foregroundStyle(TetherColor.ink)
                        .padding(.top, TetherSpace.xl)

                    TextField("6-digit code", text: $code)
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundStyle(TetherColor.text)
                        .tint(TetherColor.brand)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(TetherColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: TetherRadius.medium, style: .continuous)
                                .strokeBorder(TetherColor.border, lineWidth: 1)
                        )

                    Text("What is your partner's name?")
                        .font(TetherType.label)
                        .foregroundStyle(TetherColor.text)
                    TextField("Name", text: $name)
                        .tetherField()

                    if let error {
                        Text(error)
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.strained)
                    }

                    Button("Connect") { redeem() }
                        .tetherButton()
                        .disabled(code.trimmed.count < 6)
                        .opacity(code.trimmed.count < 6 ? 0.5 : 1)

                    Spacer()
                }
                .padding(TetherSpace.margin)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Join")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                       to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }

    private func redeem() {
        let ok = PairingService.redeem(code: code.trimmed,
                                       in: ctx,
                                       me: profile,
                                       partnerName: name.trimmed.isEmpty ? "Partner" : name.trimmed)
        if ok {
            onPaired()
        } else {
            error = "That code is not valid or has already been used."
        }
    }
}

// MARK: - Success

struct PairingSuccessView: View {
    let partnerName: String
    let onDone: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: TetherSpace.l) {
            Spacer()

            ZStack {
                Circle()
                    .fill(TetherColor.tint)
                    .frame(width: 120, height: 120)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(TetherColor.brand)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
            }

            Text("You are connected")
                .font(TetherType.display)
                .foregroundStyle(TetherColor.ink)

            Text("You and \(partnerName) are now paired. Your practice starts today.")
                .font(TetherType.body)
                .foregroundStyle(TetherColor.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button("Start together", action: onDone)
                .tetherButton()
        }
        .padding(TetherSpace.margin)
        .background(TetherColor.bg)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
        }
    }
}
