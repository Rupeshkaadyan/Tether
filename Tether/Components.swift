import SwiftUI
import UIKit

// MARK: - Haptics
//
// Light, intentional feedback tied to meaningful moments — saving a moment,
// tapping a mood, reaching a streak. Kept subtle so it feels alive, not noisy.

enum TetherHaptics {
    /// A soft tap for selections and toggles.
    static func tap() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// A gentle physical press for primary actions.
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// A confirming buzz for completed, positive actions (a saved entry, a send).
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Card container

/// A two-part row that flips from horizontal to stacked at accessibility text
/// sizes. Horizontal rows squeeze labels into hyphenated fragments once text
/// scales past the standard sizes, so those layouts have to give way.
struct AdaptiveRow<Leading: View, Trailing: View>: View {
    let stacked: Bool
    let leading: Leading
    let trailing: Trailing

    init(stacked: Bool,
         @ViewBuilder leading: () -> Leading,
         @ViewBuilder trailing: () -> Trailing) {
        self.stacked = stacked
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        if stacked {
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                leading
                trailing
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(alignment: .center, spacing: TetherSpace.m) {
                leading
                trailing
            }
        }
    }
}

struct TetherCard<Content: View>: View {
    var padded = true
    let content: Content

    /// True when the glass scene is active, which makes cards genuinely
    /// translucent rather than tinted panels.
    private var isGlass: Bool {
        SceneManager.shared.choice == .glass
    }

    init(padded: Bool = true, @ViewBuilder content: () -> Content) {
        self.padded = padded
        self.content = content()
    }

    var body: some View {
        content
            .padding(padded ? TetherSpace.l : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            // A material, not a fixed fill.
            //
            // TetherColor.surface is one hard-coded dark purple, so on a green
            // Jungle the cards stayed purple: the body was Jungle and the
            // cards were "dark mode". A material samples what is behind it, so
            // the same card reads green on Jungle, blue at Night and warm on
            // Dawn, with no per-scene colour table to maintain.
            //
            // Tinted with the surface colour on top rather than left bare, so
            // the card still reads as a raised surface and not a hole.
            // Glass gets a thicker, clearer material and almost no tint, so
            // the backdrop genuinely shows through the card. Everywhere else
            // the surface tint is heavier — reading as a solid panel is right
            // for Jungle or Night, and wrong here.
            .background(isGlass ? .ultraThinMaterial : .regularMaterial,
                        in: RoundedRectangle(cornerRadius: TetherRadius.large,
                                             style: .continuous))
            .background(TetherColor.surface
                            .opacity(isGlass ? 0.22 : 0.55),
                        in: RoundedRectangle(cornerRadius: TetherRadius.large,
                                             style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous)
                    .strokeBorder(TetherColor.border, lineWidth: 1)
            )
            .tetherShadow(.soft)
    }
}

// MARK: - Prompt card

struct PromptCard: View {
    let prompt: Prompt
    var dayLabel: String?

    var body: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            // The motif, breathing slowly. This is the emotional centre of the
            // app, so it is the one place the mark is allowed to be large.
            TetherHeroMark(width: 84, color: Color.white.opacity(0.85))
                .tetherBreathing()

            HStack {
                Chip(text: prompt.track.shortName, color: .white)
                Spacer()
                if let dayLabel {
                    Text(dayLabel.uppercased())
                        .font(TetherType.micro)
                        .foregroundStyle(.white.opacity(0.72))
                        .tracking(1)
                }
            }

            // Wrapped in LocalizedStringKey so the prompt text resolves through
            // the strings catalog. A plain String variable passed to Text does
            // not localise — this is what makes translated prompts appear.
            Text(LocalizedStringKey(prompt.body))
                .font(TetherType.prompt)
                .foregroundStyle(.white)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(TetherSpace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        )
        .tetherShadow(.floating)
        .accessibilityElement(children: .combine)
    }

    /// The brand gradient with the Tether motif swept through it and a soft
    /// light source in the corner — so the hero reads as designed rather than
    /// as a flat purple rectangle.
    private var heroBackground: some View {
        ZStack {
            TetherGradient.brand

            // The motif, enlarged and barely visible, filling the card.
            TetherSlackCurve(sag: 40)
                .stroke(Color.white.opacity(0.11),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: 320, height: 130)
                .offset(y: 26)

            TetherSlackCurve(sag: 22)
                .stroke(Color.white.opacity(0.07),
                        style: StrokeStyle(lineWidth: 1, lineCap: .round))
                .frame(width: 260, height: 100)
                .offset(x: 40, y: -54)

            // A soft light source, top-right.
            Circle()
                .fill(RadialGradient(colors: [Color.white.opacity(0.20), .clear],
                                     center: .center,
                                     startRadius: 0,
                                     endRadius: 130))
                .frame(width: 260, height: 260)
                .offset(x: 86, y: -104)
        }
    }
}

// MARK: - Visibility

/// Chooses who an entry is for: only me, or shared with the partner.
///
/// The options say what actually happens — "Only me" / "Shared" — rather than
/// the jargon, because the cost of getting this wrong is not recoverable. Once
/// someone has read a thing you did not mean to share, you cannot un-share it.
///
/// Off by default, and the shared option names the partner out loud so the
/// choice is concrete rather than abstract.
struct VisibilityPicker: View {
    @Binding var isShared: Bool
    var partnerName: String?
    /// False when there is nobody to share with. The option still shows —
    /// visibly unavailable, so the control does not appear broken.
    var canShare: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            SectionHeader(title: "Who is this for?")

            HStack(spacing: TetherSpace.s) {
                option(value: false,
                       icon: "lock.fill",
                       title: "Only me",
                       subtitle: "Nobody else sees this.",
                       enabled: true)
                option(value: true,
                       icon: "person.2.fill",
                       title: "Shared",
                       subtitle: canShare
                                 ? (partnerName == nil
                                    ? "You both see this."
                                    : "\(partnerName ?? "They") can read this.")
                                 : "Pair with your partner first.",
                       enabled: canShare)
            }
        }
    }

    private func option(value: Bool,
                        icon: String,
                        title: String,
                        subtitle: String,
                        enabled: Bool) -> some View {
        Button {
            guard enabled else { return }
            isShared = value
            TetherHaptics.light()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                    Text(title)
                        .font(TetherType.label)
                }
                .foregroundStyle(isShared == value ? .white : TetherColor.text)
                Text(subtitle)
                    .font(TetherType.micro)
                    .foregroundStyle(isShared == value
                                     ? .white.opacity(0.85)
                                     : TetherColor.faint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(TetherSpace.m)
            .background(isShared == value
                        ? AnyShapeStyle(TetherGradient.brand)
                        : AnyShapeStyle(TetherColor.surface))
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small,
                                        style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TetherRadius.small, style: .continuous)
                    .strokeBorder(isShared == value ? .clear : TetherColor.border,
                                  lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.5)
        .accessibilityAddTraits(isShared == value ? [.isSelected] : [])
        .accessibilityHidden(!enabled)
    }
}

// MARK: - Chip

struct Chip: View {
    let text: String
    var color: Color = TetherColor.brand

    var body: some View {
        HStack(spacing: TetherSpace.xs) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(color)
                .frame(width: 3, height: 12)
            Text(text)
                .font(TetherType.caption)
                .foregroundStyle(color)
        }
        .padding(.horizontal, TetherSpace.s)
        .padding(.vertical, TetherSpace.xs)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small, style: .continuous))
    }
}

// MARK: - Mood row

struct MoodRow: View {
    @Binding var selection: Int
    var isEnabled = true

    var body: some View {
        VStack(spacing: TetherSpace.s) {
            HStack(spacing: TetherSpace.s) {
                ForEach(Mood.range, id: \.self) { value in
                    Button {
                        TetherHaptics.light()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                            selection = value
                        }
                    } label: {
                        // The custom mood glyph rather than a bare number —
                        // a face reads in a glance, a digit has to be decoded.
                        ZStack {
                            Circle()
                                .fill(value == selection
                                      ? AnyShapeStyle(Mood.color(for: value))
                                      : AnyShapeStyle(TetherColor.surface))
                                .overlay(
                                    Circle().strokeBorder(
                                        value == selection ? Color.clear : TetherColor.border,
                                        lineWidth: 1)
                                )
                                .tetherShadow(value == selection ? .soft : .none)

                            Icon(TetherIcon.forMood(value),
                                 size: 23,
                                 color: value == selection ? .white : TetherColor.faint)
                        }
                        .frame(width: 48, height: 48)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 56)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!isEnabled)
                    .scaleEffect(value == selection ? 1.07 : 1)
                    .accessibilityLabel("Mood \(value) of 5, \(Mood.label(for: value))")
                    .accessibilityAddTraits(value == selection ? [.isSelected] : [])
                }
            }

            Text(Mood.label(for: selection))
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
                .contentTransition(.opacity)
                // minHeight, not height: at large accessibility sizes the
                // label needs to grow rather than be clipped to a fixed box.
                .frame(minHeight: 18)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Streak ring

struct StreakRing: View {
    let count: Int

    private var progress: CGFloat { min(CGFloat(count) / 7, 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(TetherColor.border, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 46, height: 46)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [TetherColor.thriving, TetherColor.thriving.opacity(0.6)],
                        startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 46, height: 46)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: count)

            Text("\(count)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(count > 0 ? TetherColor.text : TetherColor.faint)
                .contentTransition(.numericText())
        }
        .accessibilityElement()
        .accessibilityLabel("Streak \(count) day\(count == 1 ? "" : "s")")
    }
}

// MARK: - Pulse pill

struct PulsePill: View {
    let state: PulseState

    var body: some View {
        HStack(spacing: TetherSpace.xs) {
            Icon(state.icon, size: 14, color: state.color)
            Text(state.displayName)
                .font(TetherType.caption)
        }
        .foregroundStyle(state.color)
        .padding(.horizontal, TetherSpace.m)
        .padding(.vertical, TetherSpace.xs)
        .background(state.color.opacity(0.10))
        .clipShape(Capsule())
    }
}

// MARK: - Wisdom track card

struct WisdomTrackCard: View {
    let track: WisdomTrack
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: TetherSpace.m) {
                IconDisc(icon: track.icon, size: 46, color: track.accent, filled: isSelected)

                VStack(alignment: .leading, spacing: 3) {
                    Text(track.displayName)
                        .font(TetherType.label)
                        .foregroundStyle(TetherColor.text)
                    Text(track.blurb)
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21))
                    .foregroundStyle(isSelected ? track.accent : TetherColor.borderStrong)
            }
            .padding(TetherSpace.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TetherColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous)
                    .strokeBorder(isSelected ? track.accent : TetherColor.border,
                                  lineWidth: isSelected ? 2 : 1)
            )
            .tetherShadow(isSelected ? .lifted : .soft)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
        .accessibilityLabel("\(track.displayName). \(track.blurb)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(TetherType.label)
                .foregroundStyle(TetherColor.text)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.brand)
            }
        }
    }
}

// MARK: - Milestone toast

/// A brief, celebratory confirmation shown when a streak crosses a weekly
/// milestone. The caller owns the dismissal (a timed clear), so this stays
/// stateless and reusable.
struct MilestoneToast: View {
    let text: String

    var body: some View {
        HStack(spacing: TetherSpace.s) {
            Image(systemName: "star.fill")
            .accessibilityHidden(true)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Text(text)
                .font(TetherType.label)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, TetherSpace.l)
        .padding(.vertical, TetherSpace.m)
        .background(
            Capsule()
                .fill(TetherGradient.celebration)
                .overlay(Capsule().strokeBorder(.white.opacity(0.3), lineWidth: 1))
        )
        .tetherShadow(.floating)
        .accessibilityElement()
        .accessibilityLabel(text)
    }
}
