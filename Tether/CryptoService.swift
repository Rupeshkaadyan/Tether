import Foundation
import CryptoKit
import Security

enum CryptoError: Error {
    case keyUnavailable
    case sealFailed
    case openFailed
    case badEncoding
}

/// Device-held symmetric key for journal, coach, and memory content.
///
/// The key lives in the Keychain with `AfterFirstUnlockThisDeviceOnly`, which
/// means it is never written to iCloud Keychain, never restored onto a new
/// device, and never leaves this phone. When the backend arrives it stores only
/// ciphertext and holds no key.
///
/// Trade-off, stated plainly: lose every device and the encrypted history is
/// gone. There is no recovery path by design — that is what "we cannot read it"
/// costs. Surfaced to the user in Settings.
final class CryptoService {

    static let shared = CryptoService()

    private let service = "app.tether.encryption"
    private let account = "primary-key"
    private var cached: SymmetricKey?
    #if DEBUG
    /// Screenshot / UI-test mode: an ephemeral in-memory key so the simulator
    /// does not raise a Keychain access prompt over the UI.
    private var ephemeral: SymmetricKey?
    private var useEphemeral: Bool {
        ProcessInfo.processInfo.arguments.contains("-noKeychain")
    }
    #endif

    private init() {}

    // MARK: - Key

    var hasKey: Bool {
        #if DEBUG
        if useEphemeral { return true }
        #endif
        return loadKey() != nil
    }

    func key() throws -> SymmetricKey {
        #if DEBUG
        if useEphemeral {
            if let ephemeral { return ephemeral }
            // Deterministic so seeded demo data survives relaunches. Debug only —
            // this key is public and must never protect real content.
            let material = Data("tether-debug-key-not-for-production".utf8)
            let fresh = SymmetricKey(data: Data(SHA256.hash(data: material)))
            ephemeral = fresh
            return fresh
        }
        #endif
        if let cached { return cached }
        if let existing = loadKey() {
            cached = existing
            return existing
        }
        let fresh = SymmetricKey(size: .bits256)
        guard storeKey(fresh) else { throw CryptoError.keyUnavailable }
        cached = fresh
        return fresh
    }

    /// Irreversible. Used only by "delete all my data".
    func destroyKey() {
        cached = nil
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func loadKey() -> SymmetricKey? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return SymmetricKey(data: data)
    }

    @discardableResult
    private func storeKey(_ key: SymmetricKey) -> Bool {
        let data = key.withUnsafeBytes { Data($0) }
        var attributes = baseQuery()
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        SecItemDelete(baseQuery() as CFDictionary)
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Seal / open

    func encrypt(_ plaintext: String) throws -> String {
        guard !plaintext.isEmpty else { return plaintext }
        guard !plaintext.hasPrefix(SecureContent.prefix) else { return plaintext }

        let sealed = try AES.GCM.seal(Data(plaintext.utf8), using: try key())
        guard let combined = sealed.combined else { throw CryptoError.sealFailed }
        return SecureContent.prefix + combined.base64EncodedString()
    }

    func decrypt(_ stored: String) throws -> String {
        guard stored.hasPrefix(SecureContent.prefix) else { return stored }

        let encoded = String(stored.dropFirst(SecureContent.prefix.count))
        guard let data = Data(base64Encoded: encoded) else { throw CryptoError.badEncoding }
        let box = try AES.GCM.SealedBox(combined: data)
        let opened = try AES.GCM.open(box, using: try key())
        guard let text = String(data: opened, encoding: .utf8) else { throw CryptoError.openFailed }
        return text
    }
}

/// Call-site ergonomics. Content is stored sealed and read through `read`.
///
/// Failure policy: if sealing fails we store plaintext rather than losing the
/// user's words. `CryptoService` health is surfaced in Settings so a silent
/// fallback cannot go unnoticed.
enum SecureContent {
    static let prefix = "enc:v1:"

    static func seal(_ plaintext: String) -> String {
        (try? CryptoService.shared.encrypt(plaintext)) ?? plaintext
    }

    /// Sealed content that cannot be opened — for example after a restore to a
    /// new device, where the Keychain key did not come with it — returns a plain
    /// explanation rather than dumping base64 at the user.
    static func read(_ stored: String) -> String {
        guard isSealed(stored) else { return stored }
        do {
            return try CryptoService.shared.decrypt(stored)
        } catch {
            return "This entry can't be read on this device."
        }
    }

    static func isSealed(_ stored: String) -> Bool {
        stored.hasPrefix(prefix)
    }
}
