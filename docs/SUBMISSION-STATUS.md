# Submission status

_Last updated: 18 October 2026 · commit `9222017`_

Where Tether actually stands against App Store submission. Written to be
checked rather than trusted: every claim below was verified on the commit
above, not remembered.

---

## Verified working

| Check | Result |
|---|---|
| Build (Debug, iphonesimulator) | Succeeds |
| Launch, all five tabs | No crash, no runtime error |
| Scenes (11) | All render, zero "Invalid frame" |
| Localisation | 580 strings, en / hi / es, no gaps |
| Third-party dependencies | None |

---

## Fixed for submission

**In-App Purchase is real.** The paywall was previously a local simulation —
it slept 700 ms and then granted premium itself. That would have been rejected
under 3.1.1 (digital unlocks must use IAP) and 2.1 (the reviewer sees paid
features granted with no payment sheet). It is now StoreKit 2:

- products loaded with `Product.products(for:)`
- `product.purchase()` with verification and `finish()`
- entitlement derived **only** from `Transaction.currentEntitlements`
- `Transaction.updates` observed for renewals and refunds
- `.pending` handled as "waiting for approval"; cancel is silent

**Prices come from the store.** They were hard-coded strings, which can
disagree with App Store Connect and is treated as inaccurate metadata. Now
`displayPrice`. Trial length comes from the subscription's own
`introductoryOffer`, so the button cannot promise a trial that does not exist.

**Privacy policy is reachable in-app** (5.1.1(i)). The document existed in
`docs/` and was linked from nowhere. Settings → Legal now links the policy,
the subscription terms, and the real cancellation page (3.1.2).

**Export compliance declared.** `ITSAppUsesNonExemptEncryption = NO`, verified
present in the built Info.plist. Accurate: CryptoKit and the Keychain are
Apple's own standard algorithms, which is what the exemption covers.

**One privacy rule, one definition.** `JournalEntry.isShareable` is now the
only test for "the partner may see this". The rule had been re-derived in six
places and five of them were wrong — Two Versions, the reveal, Memory Lane,
the mood graph, recovery memory and the shared streak each leaked private
writing by content, by mood or by timing.

---

## Blocked on the developer account

These cannot be done from the repository; they need App Store Connect.

1. Create `app.tether.premium.monthly` and `app.tether.premium.annual`.
2. Sign the Paid Applications agreement — subscriptions will not load without it.
3. Add a StoreKit configuration file in Xcode so purchases can be tested in the
   simulator. **Until this exists the payment path has never completed a real
   transaction.** This is the highest-risk untested code in the app.
4. Enter the privacy policy URL in App Store Connect.

## Blocked on a decision

| Item | Why it is open |
|---|---|
| **Real two-device pairing** | `useCloudKit = false`. Everything "shared" is currently local to one device. The app is a private journal with a couples UI, not yet a couples app. Needs a paid account and two devices to build and test. |
| **Data widgets / paywalled widgets** | An App Group is required to read app data from the widget, and App Groups are unavailable under free provisioning — adding the entitlement breaks device signing. |
| **Report / block (1.2 UGC)** | The private chat is partner-only and not public, so risk is low, but it is a deliberate decision rather than an oversight. |
| **Scene consolidation** | 11 scenes, each with its own palette and silhouette. This is where the layout bugs came from; reducing to three or four would cut maintenance. No effect on submission. |

---

## Known limits, stated plainly

- Losing every device loses the journal. The key lives in the device Keychain
  and is not recoverable. Surfaced in Settings.
- The Paired study cited in planning is a self-selected, non-randomised
  evaluation. Do not put "scientifically proven" in the store listing.
- Tether is not therapy and not a crisis service. Said in the paywall; it
  should also be in the description.
