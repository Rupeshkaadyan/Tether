import SwiftUI
import SwiftData

struct JournalView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var ctx
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var allProfiles: [UserProfile]

    @State private var scope: Scope = .mine
    @State private var query = ""
    @State private var showSettings = false

    enum Scope: String, CaseIterable {
        case mine = "Mine"
        case shared = "Shared"
    }

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return allProfiles.first { $0.id == id }
    }

    private var filtered: [JournalEntry] {
        let base: [JournalEntry]
        switch scope {
        case .mine:
            base = entries.filter { $0.userID == profile.id }
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
            VStack(spacing: 0) {
                scopePicker
                searchField
                content
            }
            .background(TetherColor.bg)
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
                        Icon(option == .mine ? .privateEntry : .sharedEntry,
                             size: 15,
                             color: scope == option ? .white : TetherColor.muted)
                        Text(option.rawValue)
                            .font(TetherType.label)
                            .foregroundStyle(scope == option ? .white : TetherColor.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
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
                LazyVStack(spacing: TetherSpace.m) {
                    ForEach(filtered) { entry in
                        entryCard(entry)
                    }
                }
                .padding(.horizontal, TetherSpace.margin)
                .padding(.bottom, TetherSpace.xxl)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: TetherSpace.m) {
            Spacer()
            IconDisc(icon: scope == .mine ? .privateEntry : .sharedEntry,
                     size: 64, color: TetherColor.brand)
            Text(scope == .mine ? "Your journal starts here" : "Nothing shared yet")
                .font(TetherType.headline)
                .foregroundStyle(TetherColor.text)
            Text(scope == .mine
                 ? "Mood and one line a day. Entries appear here as you go."
                 : "Entries you mark as shared with your partner will collect here.")
                .font(TetherType.callout)
                .foregroundStyle(TetherColor.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, TetherSpace.xl)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func entryCard(_ entry: JournalEntry) -> some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                HStack(spacing: TetherSpace.s) {
                    Icon(.forMood(entry.mood), size: 18, color: Mood.color(for: entry.mood))
                    Text(entry.entryDate.shortDisplay)
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                    Spacer()
                    if scope == .shared, let owner = allProfiles.first(where: { $0.id == entry.userID }) {
                        Text(owner.displayName)
                            .font(TetherType.micro)
                            .foregroundStyle(TetherColor.faint)
                    }
                    Icon(entry.visibility == .private ? .privateEntry : .sharedEntry,
                         size: 14,
                         color: TetherColor.faint)
                }
                Text(SecureContent.read(entry.body))
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
