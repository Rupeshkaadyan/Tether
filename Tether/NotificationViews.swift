import SwiftUI

/// Shown BEFORE the system prompt. The PRD requires the ask to arrive after the
/// first value moment, and to be explained first — cold-prompting on launch is
/// the fastest way to a permanent denial.
struct NotificationPermissionSheet: View {
    let onAllow: () -> Void
    let onDecline: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: TetherSpace.xl) {
                Spacer(minLength: TetherSpace.l)

                Image(systemName: "bell.badge")
                    .font(.system(size: 36))
                    .foregroundStyle(TetherColor.brand)

                VStack(alignment: .leading, spacing: TetherSpace.s) {
                    Text("One reminder a day")
                        .font(TetherType.title)
                        .foregroundStyle(TetherColor.ink)
                    Text("That is all we will send. No streaks shaming, no re-engagement spam, no marketing.")
                        .font(TetherType.body)
                        .foregroundStyle(TetherColor.text)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: TetherSpace.m) {
                    row("clock", "At a time you choose", "Change it any time in Settings.")
                    row("person.2", "When your partner answers", "So you can read it together.")
                    row("moon.zzz", "Pause whenever you want", "Prompts stop. Nothing is lost.")
                }

                Spacer()

                Button("Turn on reminders") {
                    onAllow()
                    dismiss()
                }
                .tetherButton()

                Button("Not now") {
                    onDecline()
                    dismiss()
                }
                .tetherButton(.tertiary)
            }
            .padding(TetherSpace.margin)
            .background { TetherBackdrop() }
        }
    }

    private func row(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: TetherSpace.m) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundStyle(TetherColor.brand)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TetherType.label)
                    .foregroundStyle(TetherColor.text)
                Text(detail)
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
