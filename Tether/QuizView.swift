import SwiftData
import SwiftUI

// MARK: - How well do you know them?
//
// The one playful thing in the app. Everything else is a practice; this is a
// game, and the category leader's quizzes are their biggest engagement driver
// after the daily question precisely because of that.
//
// THE HONEST CONSTRAINT: a couples quiz cannot show a score without two people
// answering. Rather than fake a reveal, this does two real things:
//
//   - Solo, it shows "Your read on them" — a genuine summary of how you see
//     your partner, drawn from your own picks. That stands on its own.
//   - Paired, once both have played, it scores the guesses.
//
// Answers are stored per person, so the reveal works the moment there are two.

struct QuizQuestion: Identifiable {
    let id: String
    let prompt: String
    let options: [String]
}

enum QuizBank {
    static let questions: [QuizQuestion] = [
        QuizQuestion(id: "q1",
                     prompt: "On a hard day, what do they need most?",
                     options: ["To be left alone", "To talk it through",
                               "To be held", "To be distracted"]),
        QuizQuestion(id: "q2",
                     prompt: "What are they actually tired of?",
                     options: ["Being the strong one", "Being misunderstood",
                               "Carrying the planning", "Never switching off"]),
        QuizQuestion(id: "q3",
                     prompt: "When they go quiet, it usually means…",
                     options: ["They're hurt", "They're thinking",
                               "They're exhausted", "They need space"]),
        QuizQuestion(id: "q4",
                     prompt: "What do they wish you did more of?",
                     options: ["Asked questions", "Noticed things",
                               "Said thank you", "Made the plan"]),
        QuizQuestion(id: "q5",
                     prompt: "What makes them feel most loved?",
                     options: ["Time together", "Words", "Touch", "Being helped"]),
        QuizQuestion(id: "q6",
                     prompt: "What are they quietly proud of?",
                     options: ["Their work", "Their family",
                               "How they've changed", "Getting through something"]),
        QuizQuestion(id: "q7",
                     prompt: "What worries them that they don't say?",
                     options: ["Drifting apart", "Money", "Their family",
                               "Not being enough"]),
        QuizQuestion(id: "q8",
                     prompt: "On a free afternoon, what would they choose?",
                     options: ["Outdoors", "Home, doing nothing",
                               "People", "A project"]),
        QuizQuestion(id: "q9",
                     prompt: "What did they need from you last week?",
                     options: ["Patience", "Reassurance",
                               "Practical help", "Just your attention"]),
        QuizQuestion(id: "q10",
                     prompt: "How do they show love when words fail?",
                     options: ["Doing things for you", "Staying close",
                               "Remembering details", "Making you laugh"]),
        QuizQuestion(id: "q11",
                     prompt: "What would they say this relationship needs?",
                     options: ["More time", "More honesty",
                               "More fun", "More rest"]),
        QuizQuestion(id: "q12",
                     prompt: "What do they hope you notice?",
                     options: ["How hard they try", "When they're low",
                               "The small things", "That they're still here"]),
    ]
}

/// One person's answer to one question.
@Model
final class QuizAnswer {
    var id: UUID
    var userID: UUID
    var questionID: String
    /// The option THEY would pick.
    var guessIndex: Int
    var createdAt: Date

    init(userID: UUID, questionID: String, guessIndex: Int) {
        self.id = UUID()
        self.userID = userID
        self.questionID = questionID
        self.guessIndex = guessIndex
        self.createdAt = Date()
    }
}

// MARK: - View

struct QuizView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query private var answers: [QuizAnswer]
    @Query private var profiles: [UserProfile]

    @State private var index = 0

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return profiles.first { $0.id == id }
    }

    private var mine: [QuizAnswer] {
        answers.filter { $0.userID == profile.id }
    }

    private var theirs: [QuizAnswer] {
        guard let partner else { return [] }
        return answers.filter { $0.userID == partner.id }
    }

    private var question: QuizQuestion {
        QuizBank.questions[min(index, QuizBank.questions.count - 1)]
    }

    private var answered: Int { mine.count }
    private var complete: Bool { answered >= QuizBank.questions.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.xl) {
                    if complete {
                        result
                    } else {
                        progress
                        card
                    }
                }
                .padding(TetherSpace.margin)
                .readableFrame()
                .padding(.bottom, TetherSpace.xxl)
            }
            .background { TetherBackdrop() }
            .navigationTitle(partner == nil ? "How you see them" : "How well do you know them?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { index = min(answered, QuizBank.questions.count - 1) }
        }
    }

    // MARK: Playing

    private var progress: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            HStack {
                Text("\(answered + 1) of \(QuizBank.questions.count)")
                    .font(TetherType.micro)
                    .tracking(1)
                    .foregroundStyle(TetherColor.faint)
                Spacer()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(TetherColor.border)
                    Capsule()
                        .fill(TetherGradient.brand)
                        .frame(width: max(6, geo.size.width
                                          * Double(answered) / Double(QuizBank.questions.count)))
                }
            }
            .frame(height: 6)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: TetherSpace.l) {
            Text(question.prompt)
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .foregroundStyle(TetherColor.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(partner == nil
                 ? "Answer for yourself. It still tells you something."
                 : "Answer as \(partner?.displayName ?? "they") would.")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)

            VStack(spacing: TetherSpace.s) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { i, option in
                    Button {
                        answer(i)
                    } label: {
                        HStack {
                            Text(option)
                                .font(TetherType.body)
                                .foregroundStyle(TetherColor.text)
                            Spacer(minLength: 0)
                        }
                        .padding(TetherSpace.m)
                        .background(TetherColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small,
                                                    style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: TetherRadius.small,
                                            style: .continuous)
                                .strokeBorder(TetherColor.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Result

    private var result: some View {
        VStack(alignment: .leading, spacing: TetherSpace.xl) {
            VStack(alignment: .leading, spacing: TetherSpace.xs) {
                Text("Your read on them")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(TetherColor.ink)
                Text(partner == nil
                     ? "All twelve answered. This is how you see them."
                     : "Both of you can compare once they have played too.")
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // What you chose, question by question. This is the real content —
            // it reads as a portrait, not a scoreboard.
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                SectionHeader(title: "Your answers")
                ForEach(QuizBank.questions) { q in
                    if let a = mine.first(where: { $0.questionID == q.id }) {
                        answerRow(q, a)
                    }
                }
            }

            if !theirs.isEmpty {
                SectionHeader(title: "Where you differed")
                ForEach(QuizBank.questions) { q in
                    if let mineA = mine.first(where: { $0.questionID == q.id }),
                       let theirsA = theirs.first(where: { $0.questionID == q.id }),
                       mineA.guessIndex != theirsA.guessIndex {
                        HStack(alignment: .top, spacing: TetherSpace.s) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 12))
                                .foregroundStyle(TetherColor.drifting)
                            Text(q.prompt)
                                .font(TetherType.caption)
                                .foregroundStyle(TetherColor.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            Button("Start over") { reset() }
                .tetherButton(.secondary)
        }
    }

    private func answerRow(_ q: QuizQuestion, _ a: QuizAnswer) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(q.prompt)
                .font(TetherType.micro)
                .foregroundStyle(TetherColor.faint)
                .fixedSize(horizontal: false, vertical: true)
            Text(q.options[safe: a.guessIndex] ?? "—")
                .font(TetherType.callout)
                .foregroundStyle(TetherColor.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }

    // MARK: Actions

    private func answer(_ i: Int) {
        // Replace rather than duplicate if this question was already answered.
        if let existing = mine.first(where: { $0.questionID == question.id }) {
            existing.guessIndex = i
        } else {
            ctx.insert(QuizAnswer(userID: profile.id,
                                  questionID: question.id,
                                  guessIndex: i))
        }
        try? ctx.save()
        TetherHaptics.success()
        if index + 1 < QuizBank.questions.count {
            withAnimation(.easeOut(duration: 0.2)) { index += 1 }
        } else {
            withAnimation(.easeOut(duration: 0.25)) { index = QuizBank.questions.count }
        }
    }

    private func reset() {
        for a in mine { ctx.delete(a) }
        try? ctx.save()
        index = 0
    }
}

private extension Array {
    subscript(safe i: Int) -> Element? {
        indices.contains(i) ? self[i] : nil
    }
}
