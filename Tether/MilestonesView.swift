import SwiftData
import SwiftUI

// MARK: - Milestones on Home
//
// The milestones themselves already existed, computed in GrowthViews and shown
// in the Grow tab. What was missing is that you had to go looking for them.
//
// This adds a single Home card that surfaces the next one — because a milestone
// you never see is not a milestone. It reuses the existing model and the
// existing `Milestones.compute`; there is no second definition of anything.
//
// The framing is deliberate: progress is shown as "3 to go" rather than "7/30".
// One is a nudge. The other is a grade.

struct MilestoneCard: View {
    let milestones: [Milestone]

    /// The nearest unearned milestone.
    private var next: Milestone? {
        milestones
            .filter { !$0.isEarned }
            .min { ($0.goal - $0.current) < ($1.goal - $1.current) }
    }

    /// The highest goal already earned.
    private var earned: Milestone? {
        milestones.filter(\.isEarned).max { $0.goal < $1.goal }
    }

    var body: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                HStack(spacing: TetherSpace.xs) {
                    TetherHeroMark(width: 26,
                                   color: TetherColor.brand.opacity(0.55),
                                   sag: 4, lineWidth: 1.5, dotRadius: 2)
                    Text("MILESTONES")
                        .font(TetherType.micro)
                        .tracking(1)
                        .foregroundStyle(TetherColor.faint)
                    Spacer(minLength: 0)
                    if let earned {
                        Text(earned.title)
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.brand)
                    }
                }

                if let next {
                    Text(next.title)
                        .font(TetherType.callout)
                        .foregroundStyle(TetherColor.text)

                    let remaining = max(0, next.goal - next.current)
                    Text(remaining == 1 ? "One to go." : "\(remaining) to go.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(TetherColor.border)
                            Capsule()
                                .fill(TetherGradient.brand)
                                .frame(width: max(6, geo.size.width * next.progress))
                        }
                    }
                    .frame(height: 6)
                } else {
                    Text("Every milestone earned.")
                        .font(TetherType.callout)
                        .foregroundStyle(TetherColor.text)
                    Text("You have done all of this.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Full screen

/// The whole list, in one place. Reachable by tapping the Home card.
struct MilestonesView: View {
    let milestones: [Milestone]
    @Environment(\.dismiss) private var dismiss

    private var earned: [Milestone] { milestones.filter(\.isEarned) }
    private var ahead: [Milestone] { milestones.filter { !$0.isEarned } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.xl) {
                    header
                    if !ahead.isEmpty { section("Ahead", ahead) }
                    if !earned.isEmpty { section("Earned", earned.reversed()) }
                }
                .padding(TetherSpace.margin)
                .readableFrame()
                .padding(.bottom, TetherSpace.xxl)
            }
            .background { TetherBackdrop() }
            .navigationTitle("Milestones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TetherSpace.xs) {
            Text("\(earned.count) of \(milestones.count)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(TetherColor.ink)
            Text("Counts of things you actually did — never time spent in an app. There is no behind here, only not yet.")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func section(_ title: String, _ items: [Milestone]) -> some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            SectionHeader(title: title)
            ForEach(items) { milestone in
                row(milestone)
            }
        }
    }

    private func row(_ milestone: Milestone) -> some View {
        TetherCard {
            HStack(spacing: TetherSpace.m) {
                ZStack {
                    Circle()
                        .fill(milestone.isEarned
                              ? AnyShapeStyle(TetherGradient.brand)
                              : AnyShapeStyle(TetherColor.surfaceSunken))
                        .frame(width: 40, height: 40)
                    Image(systemName: milestone.symbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(milestone.isEarned ? Color.white : TetherColor.faint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.title)
                        .font(TetherType.label)
                        .foregroundStyle(milestone.isEarned ? TetherColor.text : TetherColor.muted)
                    Text(milestone.detail)
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if milestone.isEarned {
                    Image(systemName: "checkmark")
                    .accessibilityHidden(true)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TetherColor.brand)
                } else {
                    Text("\(max(0, milestone.goal - milestone.current))")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.faint)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
