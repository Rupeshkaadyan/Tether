import SwiftUI

// MARK: - Card container

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
        HStack(spacing: TetherSpace.m) {
            ForEach(Mood.range, id: \.self) { value in
                Button {
                    selection = value
                } label: {
                    Circle()
                        .fill(value == selection ? Mood.color(for: value) : TetherColor.surface)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    value == selection ? Mood.color(for: value) : TetherColor.border,
                                    lineWidth: value == selection ? 0 : 1
                                )
                        )
                        .overlay(
                            Text("\(value)")
                                .font(TetherType.caption)
                                .foregroundStyle(value == selection ? .white : TetherColor.muted)
                        )
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
                .accessibilityLabel("Mood \(value) of 5, \(Mood.label(for: value))")
                .accessibilityAddTraits(value == selection ? [.isSelected] : [])
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Streak ring

struct StreakRing: View {
    let count: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(TetherColor.border, lineWidth: 4)
                .frame(width: 44, height: 44)
            Circle()
                .trim(from: 0, to: min(CGFloat(count) / 7, 1))
                .stroke(TetherColor.thriving, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(TetherColor.text)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Streak \(count) days")
    }
}

// MARK: - Pulse pill

struct PulsePill: View {
    let state: PulseState

    var body: some View {
        HStack(spacing: TetherSpace.xs) {
            Image(systemName: state.symbol)
                .font(.system(size: 12))
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
                ZStack {
                    Circle()
                        .fill(isSelected ? track.accent : track.accent.opacity(0.13))
                        .frame(width: 46, height: 46)
                    Image(systemName: track.symbol)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(isSelected ? .white : track.accent)
                }

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
