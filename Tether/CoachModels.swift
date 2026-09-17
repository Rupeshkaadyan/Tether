import Foundation
import SwiftData

enum CoachRole: String, Codable {
    case user, assistant
}

@Model
final class AIConversation {
    var id: UUID
    var ownerID: UUID
    var title: String
    var createdAt: Date
    var lastMessageAt: Date

    init(ownerID: UUID, title: String = "New conversation") {
        self.id = UUID()
        self.ownerID = ownerID
        self.title = title
        self.createdAt = Date()
        self.lastMessageAt = Date()
    }
}

@Model
final class AIMessage {
    var id: UUID
    var conversationID: UUID
    var roleRaw: String
    /// Holds ciphertext once CryptoKit lands. Plaintext on device for now.
    var body: String
    var usedMemory: Bool
    var safetyFlagged: Bool
    var createdAt: Date

    init(conversationID: UUID,
         role: CoachRole,
         body: String,
         usedMemory: Bool = false,
         safetyFlagged: Bool = false) {
        self.id = UUID()
        self.conversationID = conversationID
        self.roleRaw = role.rawValue
        self.body = body
        self.usedMemory = usedMemory
        self.safetyFlagged = safetyFlagged
        self.createdAt = Date()
    }

    var role: CoachRole {
        get { CoachRole(rawValue: roleRaw) ?? .user }
        set { roleRaw = newValue.rawValue }
    }
}

/// The couple-memory layer. This is the defensible part of the coach — a
/// stateless chatbot is table stakes in 2026; remembering what happened three
/// weeks ago is not.
///
/// Retrieval is keyword-scored locally for now. `CoachEngine` hides it behind a
/// protocol so a pgvector embedding search can replace it without touching
/// callers.
@Model
final class AIMemory {
    var id: UUID
    var ownerID: UUID
    var sourceRaw: String
    var sourceID: UUID
    var text: String
    var keywords: String
    var visibilityRaw: String
    var createdAt: Date

    init(ownerID: UUID,
         source: EntrySource,
         sourceID: UUID,
         text: String,
         keywords: [String],
         visibility: Visibility = .shared) {
        self.id = UUID()
        self.ownerID = ownerID
        self.sourceRaw = source.rawValue
        self.sourceID = sourceID
        self.text = text
        self.keywords = keywords.joined(separator: " ")
        self.visibilityRaw = visibility.rawValue
        self.createdAt = Date()
    }

    var source: EntrySource {
        get { EntrySource(rawValue: sourceRaw) ?? .journal }
        set { sourceRaw = newValue.rawValue }
    }

    var visibility: Visibility {
        get { Visibility(rawValue: visibilityRaw) ?? .shared }
        set { visibilityRaw = newValue.rawValue }
    }

    var keywordList: [String] {
        keywords.split(separator: " ").map(String.init)
    }
}
