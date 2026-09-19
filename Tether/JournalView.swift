import SwiftData
import SwiftUI
import UIKit

struct JournalView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var ctx
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var allProfiles: [UserProfile]

    @State private var scope: Scope = .onlyMe
    @State private var query = ""
    @State private var showSettings = false

    /// The two tabs are MUTUALLY EXCLUSIVE, and the names now say so.
    ///
    /// They used to be "Mine" and "Shared", where Mine meant everything I
    /// wrote — private AND shared — and Shared meant the shared ones. So a
    /// single entry appeared in both tabs, and the journal looked like it was
    /// showing the same thing twice. "Mine" and "Shared" also read as a
    /// false pair: as if shared entries were somehow not mine.
    ///
    /// "Only me" and "Shared" are opposites, which is what they actually are:
    /// what nobody else can see, and what we both can.
    enum Scope: String, CaseIterable {
        case onlyMe = "Only me"
        case shared = "Shared"
    }

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return allProfiles.first { $0.id == id }
    }

    private var filtered: [JournalEntry] {
        let base: [JournalEntry]
        switch scope {
        case .onlyMe:
            // Strictly what nobody else can see. A shared entry is NOT here —
            // it lives in the Shared tab, and appearing in both was the bug.
            base = entries.filter {
                $0.userID == profile.id && $0.visibility == .private
            }
        case .shared:
            base = entries.filter { entry in
                guard entry.visibility == .shared else { return false }
                return entry.userID == profile.id || entry.userID == partner?.id
            }
        }
        guard !query.trimmed.isEmpty else { return base }
        let needle = query.trimmed.lowercased()
        return base.filter { SecureContent.read($0.body).lowercased().contains(needle) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // The backdrop is a SIBLING of the content, not its background.
                //
                // As a `.background` it sized to the VStack, and the VStack
                // shrinks when the keyboard comes up for the search field — so
                // tapping search collapsed the whole backdrop into a small
                // block at the top and the screen looked broken.
                //
                // As a sibling it fills the ZStack, and ignoring the keyboard's
                // safe area keeps it filling the screen even while the content
                // above it moves.
                TetherBackdrop()
                    .ignoresSafeArea(.keyboard, edges: .bottom)

                VStack(spacing: 0) {
                    scopePicker
                    searchField
                    content
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { showSettings = true } label: {
                        Icon(.settings, size: 21, color: TetherColor.muted)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView(profile: profile) }
        }
    }

    // MARK: - Pieces

    private var scopePicker: some View {
        HStack(spacing: TetherSpace.s) {
            ForEach(Scope.allCases, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { scope = option }
                } label: {
                    HStack(spacing: 6) {
                        Icon(option == .onlyMe ? .privateEntry : .sharedEntry,
                             size: 15,
                             color: scope == option ? .white : TetherColor.muted)
                        Text(option.rawValue)
                            .font(TetherType.label)
                            .foregroundStyle(scope == option ? .white : TetherColor.muted)
                    }
                    .frame(maxWidth: .infinity)
                    // minHeight: the label inside grows at accessibility text
                    // sizes, and a hard 42 would slice it off.
                    .frame(minHeight: 42)
                    .background(scope == option ? AnyShapeStyle(TetherGradient.brand)
                                                : AnyShapeStyle(TetherColor.surface))
                    .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: TetherRadius.small, style: .continuous)
                            .strokeBorder(scope == option ? .clear : TetherColor.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(scope == option ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, TetherSpace.margin)
        .padding(.bottom, TetherSpace.s)
    }

    private var searchField: some View {
        HStack(spacing: TetherSpace.s) {
            Icon(.search, size: 17, color: TetherColor.faint)
            TextField("Search your entries", text: $query)
                .font(TetherType.body)
                .foregroundStyle(TetherColor.text)
                .tint(TetherColor.brand)
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Icon(.close, size: 15, color: TetherColor.faint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, TetherSpace.l)
        .frame(height: 46)
        .background(TetherColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TetherRadius.small, style: .continuous)
                .strokeBorder(TetherColor.border, lineWidth: 1)
        )
        .padding(.horizontal, TetherSpace.margin)
        .padding(.bottom, TetherSpace.m)
    }

    @ViewBuilder
    private var content: some View {
        if filtered.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.xl) {
                    ForEach(grouped, id: \.month) { group in
                        VStack(alignment: .leading, spacing: TetherSpace.m) {
                            monthHeader(group.month)
                            ForEach(group.entries) { entry in
                                timelineRow(entry,
                                            isLast: entry.id == group.entries.last?.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, TetherSpace.margin)
                .padding(.bottom, TetherSpace.xxl)
                .readableFrame()
            }
        }
    }

    // MARK: - Timeline

    /// Entries grouped by month, newest first. The month headings give the
    /// journal its rhythm so it does not read as an endless list of identical
    /// cards.
    private var grouped: [(month: Date, entries: [JournalEntry])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: filtered) { entry -> Date in
            let comps = cal.dateComponents([.year, .month], from: entry.entryDate)
            return cal.date(from: comps) ?? entry.entryDate
        }
        return groups
            .map { (month: $0.key,
                    entries: $0.value.sorted { $0.entryDate > $1.entryDate }) }
            .sorted { $0.month > $1.month }
    }

    /// When the entry was written. Shown beside the date so the timeline has
    /// the texture of a day, not just a sequence of records.
    private func timeOfDayLabel(_ date: Date) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12:  return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default:      return "night"
        }
    }

    private func monthHeader(_ month: Date) -> some View {
        Text(month.formatted(.dateTime.month(.wide).year()))
            .font(TetherType.title)
            .foregroundStyle(TetherColor.ink)
            .padding(.top, TetherSpace.s)
    }

    /// A timeline row: a mood-coloured node on a spine, the date, then the
    /// entry. Deliberately not a card — the spine carries the structure so the
    /// writing can breathe.
    private func timelineRow(_ entry: JournalEntry, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: TetherSpace.m) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Mood.color(for: entry.mood))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle().stroke(TetherColor.surface, lineWidth: 2)
                    )
                if !isLast {
                    Rectangle()
                        .fill(TetherColor.border)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: TetherSpace.xs) {
                HStack(spacing: TetherSpace.s) {
                    Text(entry.entryDate.formatted(
                        .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                         + " · " + timeOfDayLabel(entry.entryDate))
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                    Spacer(minLength: 0)
                    Icon(entry.visibility == .private ? .privateEntry : .sharedEntry,
                         size: 13,
                         color: TetherColor.faint)
                }

                Text(SecureContent.read(entry.body))
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.text)
                    .fixedSize(horizontal: false, vertical: true)

                if let audio = entry.voiceData {
                    Button {
                        VoiceNoteService.shared.togglePlayback(audio, id: entry.id)
                    } label: {
                        HStack(spacing: TetherSpace.xs) {
                            Image(systemName: VoiceNoteService.shared.playingID == entry.id
                                  ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 19))
                                .foregroundStyle(TetherColor.brand)
                            Text(VoiceNoteService.shared.playingID == entry.id
                                 ? "Playing…" : "Voice note")
                                .font(TetherType.caption)
                                .foregroundStyle(TetherColor.brand)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Play voice note")
                }

                if let data = entry.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium,
                                                    style: .continuous))
                }

                HStack(spacing: TetherSpace.xs) {
                    Text(Mood.label(for: entry.mood))
                        .font(TetherType.micro)
                        .foregroundStyle(TetherColor.faint)
                    if scope == .shared,
                       let owner = allProfiles.first(where: { $0.id == entry.userID }) {
                        Text("·")
                            .font(TetherType.micro)
                            .foregroundStyle(TetherColor.faint)
                        Text(owner.displayName)
                            .font(TetherType.micro)
                            .foregroundStyle(TetherColor.faint)
                    }
                }
            }
            .padding(.bottom, TetherSpace.m)
        }
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        TetherEmptyState(
            title: scope == .onlyMe ? "Your journal starts here" : "Nothing shared yet",
            message: scope == .onlyMe
                ? "Mood and one line a day. Entries appear here as you go."
                : "Entries you mark as shared with your partner will collect here."
        )
    }
}
