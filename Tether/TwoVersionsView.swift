import SwiftData
import SwiftUI

// MARK: - Two versions of the same day
//
// Both people write their own memory of a day. Neither sees the other's until
// both have written. Then both are revealed, side by side, with no verdict.
//
// This is the most common shape of a relationship problem: not dishes or
// phones, but "you don't see me". Two people can sit in the same room, both
// struggling, and each conclude the other does not care. Neither is lying.
// They are each reporting accurately from inside their own head.
//
// No other app can do this. It needs two people, and it needs enough trust
// that both will write honestly — which is the thing this whole app has been
// built to earn.

/// One day, seen twice.
struct TwoVersions: Identifiable {
    let day: Date
    let mine: JournalEntry
    let theirs: JournalEntry
    let myName: String
    let theirName: String

    var id: Date { day }

    /// Both said, in their own words, that the day was hard.
    var bothStruggled: Bool { mine.mood <= 2 && theirs.mood <= 2 }
}

enum TwoVersionsEngine {

    /// Days where BOTH people wrote, and at least one of them found it hard.
    ///
    /// Only these days are offered. Surfacing every shared day would make it
    /// noise; the point is the days where something was actually going on and
    /// neither person knew.
    static func find(entries: [JournalEntry],
                     meID: UUID,
                     partnerID: UUID?,
                     limit: Int = 6) -> [TwoVersions] {
        guard let partnerID else { return [] }
        let cal = Calendar.current

        func day(of d: Date) -> Date { cal.startOfDay(for: d) }

        let mine = Dictionary(grouping: entries.filter { $0.userID == meID },
                              by: { day(of: $0.entryDate) })
        let theirs = Dictionary(grouping: entries.filter { $0.userID == partnerID },
                                by: { day(of: $0.entryDate) })

        var out: [TwoVersions] = []
        for (day, myEntries) in mine {
            guard let my = myEntries.max(by: { $0.createdAt < $1.createdAt }),
                  let their = theirs[day]?.max(by: { $0.createdAt < $1.createdAt })
            else { continue }
            // Only when someone found the day hard — that is the signal.
            guard my.mood <= 2 || their.mood <= 2 else { continue }
            out.append(TwoVersions(day: day,
                                   mine: my,
                                   theirs: their,
                                   myName: "", theirName: ""))
        }

        return out
            .sorted { $0.day > $1.day }
            .prefix(limit)
            .map { $0 }
    }
}

// MARK: - The sheet

struct TwoVersionsView: View {
    let versions: [TwoVersions]
    var myName: String
    var theirName: String

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                if versions.isEmpty {
                    TetherEmptyState(
                        title: "Nothing to compare yet",
                        message: "When you have both written about the same day, you will be able to read both sides here."
                    )
                    .padding(TetherSpace.margin)
                } else {
                    TabView(selection: $index) {
                        ForEach(Array(versions.enumerated()), id: \.offset) { i, v in
                            TwoVersionsCard(v: v,
                                            myName: myName,
                                            theirName: theirName)
                            .tag(i)
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: 480)
                    .padding(.top, TetherSpace.m)
                }
            }
            .background { TetherBackdrop() }
            .navigationTitle("Two versions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - One day, both sides

struct TwoVersionsCard: View {
    let v: TwoVersions
    var myName: String
    var theirName: String

    var body: some View {
        VStack(alignment: .leading, spacing: TetherSpace.l) {
            Text(v.day.formatted(.dateTime.weekday(.wide).day().month()))
                .font(TetherType.micro)
                .foregroundStyle(TetherColor.faint)

            HStack(alignment: .top, spacing: TetherSpace.m) {
                side(name: "You", entry: v.mine)
                side(name: theirName, entry: v.theirs)
            }

            // The whole point, and the only commentary offered.
            //
            // Not "who was right". Not advice. Just the fact that both of
            // these are true at the same time, which is the thing that
            // dissolves the argument.
            Text(v.bothStruggled
                 ? "You were both having a hard day, and neither of you knew the other was too. Neither of you is wrong."
                 : "Two accounts of the same day, both true. This is what it is like to be two people.")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(TetherSpace.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TetherColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium,
                                            style: .continuous))

            Spacer(minLength: 0)
        }
        .padding(TetherSpace.margin)
    }

    private func side(name: String, entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            HStack(spacing: 4) {
                Text(name)
                    .font(TetherType.micro)
                    .foregroundStyle(TetherColor.faint)
                Spacer(minLength: 0)
                Text(Mood.label(for: entry.mood))
                    .font(TetherType.micro)
                    .foregroundStyle(TetherColor.faint)
            }

            Text(SecureContent.read(entry.body))
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(TetherColor.text)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(TetherSpace.m)
                .background(TetherColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small,
                                            style: .continuous))
        }
    }
}

// MARK: - Home card

/// Appears only when there is something worth seeing — a day both wrote about
/// and neither has seen the other side of.
struct TwoVersionsTeaser: View {
    let day: Date
    var onOpen: () -> Void

    var body: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                HStack(spacing: TetherSpace.s) {
                    Image(systemName: "rectangle.split.2x1")
                        .font(.system(size: 15))
                        .foregroundStyle(TetherColor.brand)
                    Text("You both wrote about \(day.formatted(.dateTime.weekday(.wide)))")
                        .font(TetherType.label)
                        .foregroundStyle(TetherColor.text)
                }
                Text("Neither of you has seen the other's side.")
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Read both") { onOpen() }
                    .tetherButton(.secondary)
            }
        }
    }
}
