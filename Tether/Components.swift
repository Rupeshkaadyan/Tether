import SwiftUI

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

    init(padded: Bool = true, @ViewBuilder content: () -> Content) {
        self.padded = padded
        self.content = content()
    }

    var body: some View {
        content
            .padding(padded ? TetherSpace.l : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TetherColor.surface)
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
            HStack {
                Chip(text: prompt.track.shortName, color: .white)
                Spacer()
                if let dayLabel {
                    Text(dayLabel)
                        .font(TetherType.micro)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            Text(prompt.body)
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(TetherSpace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TetherGradient.brand)
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous))
        .tetherShadow(.lifted)
        .accessibilityElement(children: .combine)
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
                .frame(height: 18)
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
