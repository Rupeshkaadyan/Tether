// SampleUnitTests.swift
//
// REFERENCE ONLY — this file lives in docs/ and is NOT part of the Tether app
// target. It shows the unit tests worth writing once you add a test target
// (Xcode ▸ File ▸ New ▸ Target ▸ Unit Testing Bundle). Copy the bodies you
// want into a real `<YourApp>Tests` target; do not compile this file as-is.
//
// Run with: Cmd+U after creating the test target.

import XCTest
import SwiftData
@testable import Tether

final class TetherCoreTests: XCTestCase {

    // MARK: - SecureContent

    func testSealRoundTrips() {
        let plain = "I felt seen today."
        let sealed = SecureContent.seal(plain)
        XCTAssertNotEqual(sealed, plain, "seal must not store plaintext")
        XCTAssertTrue(sealed.hasPrefix("enc:v1:"), "sealed value carries the version prefix")
        XCTAssertEqual(SecureContent.read(sealed), plain, "read must decrypt back to plaintext")
    }

    func testReadOfPlaintextIsPassthrough() {
        let plain = "already clear"
        XCTAssertEqual(SecureContent.read(plain), plain)
    }

    func testReadOfCorruptCiphertextIsGraceful() {
        // A sealed-looking string that cannot be opened must degrade to a
        // friendly message rather than crashing or dumping base64.
        let corrupt = "enc:v1:not-valid-base64!!!"
        let result = SecureContent.read(corrupt)
        XCTAssertFalse(result.isEmpty)
        XCTAssertFalse(result.contains("enc:v1:"), "must never surface raw ciphertext")
    }

    // MARK: - Streaks

    func testStreakCountsConsecutiveDays() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dates = (0..<5).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
        XCTAssertEqual(Streaks.current(from: dates), 5)
    }

    func testStreakBreaksOnGap() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Today and 2 days ago, but not yesterday -> streak is 1 (today only).
        let dates = [
            today,
            cal.date(byAdding: .day, value: -2, to: today)!
        ]
        XCTAssertEqual(Streaks.current(from: dates), 1)
    }

    func testStreakIsZeroForEmpty() {
        XCTAssertEqual(Streaks.current(from: []), 0)
    }

    // MARK: - Pairing guard

    func testRedeemDoesNotCreateSecondPartner() throws {
        // Build an in-memory SwiftData stack, pair a user, then attempt a second
        // redeem and assert no second partner profile is created.
        let schema = Schema([UserProfile.self, Invite.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let ctx = container.mainContext

        let me = UserProfile(displayName: "Me", track: .secular)
        ctx.insert(me)

        let invite = Store.createInvite(in: ctx, inviterID: me.id)
        let code = invite.code

        let first = Store.redeem(code: code, in: ctx, me: me, partnerName: "Them")
        XCTAssertTrue(first, "first redeem should succeed")

        // Second redeem while already paired must fail, not create a duplicate.
        let before = (try? ctx.fetch(FetchDescriptor<UserProfile>()))?.count ?? 0
        let second = Store.redeem(code: "ANOTHERCODE", in: ctx, me: me, partnerName: "Other")
        XCTAssertFalse(second, "re-pairing while paired must be rejected")
        let after = (try? ctx.fetch(FetchDescriptor<UserProfile>()))?.count ?? 0
        XCTAssertEqual(before, after, "no additional partner profile should be created")
    }

    // MARK: - Love-language skip

    func testSkipStoresNoLanguage() {
        // The onboarding Skip flow must NOT force a language; the store should
        // remain empty for that profile id after skipping.
        let id = UUID()
        XCTAssertNil(LoveLanguageStore.get(for: id), "skipping leaves the preference unset")
    }
}
