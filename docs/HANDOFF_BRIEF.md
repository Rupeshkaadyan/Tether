# Tether — App Overview & Handoff Brief

Use this to brief another AI (or a designer/developer) on what Tether is, what
already exists, and where improvements are wanted.

---

## 1. What the app does

**Tether is a private, one-minute-a-day check-in app for couples.** Each day
both partners answer one prompt, tap how they feel (1–5), and can add a short
note. Over time the app builds a picture of how the relationship is doing — and
gives each person a gentle place to reflect, without either partner being able
to read the other's private words.

Core loop: **one prompt → one mood → one optional note → done in under a minute.**

- **Daily check-in** — a prompt chosen from the person's wisdom tradition, a
  1–5 mood tap, and an optional note (typed or dictated).
- **Private journal** — free-form entries, encrypted on device.
- **Coach** — a conversational guide grounded in the person's own entries and
  their chosen wisdom path. Currently runs on-device (no API key).
- **Relationship Pulse** — a computed read on the relationship:
  Thriving / Drifting / Strained, plus a trend (rising / steady / falling).
- **Insights** — charts and stats over 7 / 14 / 30 days: mood over time,
  streak, active days, entry count, average mood, mood mix, love-language
  reflection, and best/hardest day callouts.
- **Grow** — weekly reflection, a 7-day connection challenge, and milestones.
- **Pairing** — invite a partner by link, QR, or 6-digit code. Works solo first;
  if nobody joins within 72 hours the app stops waiting and hands you the full
  solo product.

## 2. Who it's for — and the moat

Tether is built to be **globally inclusive**. Each person picks their own wisdom
path — **Secular/Psychology, Biblical, Vedic & Dharmic, or Quranic** — and that
choice is **per partner, not per couple**. So an interfaith couple each gets
guidance in their own tradition while sharing the same relationship. That is the
differentiator: most relationship apps assume one worldview.

Other deliberate choices:
- **All four tracks ship live.** No tradition is ever marked "coming soon."
- **Privacy-first.** Entries are sealed with a device-only key; the app cannot
  read them and there is no way to recover them if every device is lost.
- **No account.** You can use the whole app without telling anyone who you are.

## 3. Current feature inventory

| Area | What's there |
|---|---|
| Onboarding | name, wisdom track, love-language quiz (skippable), first prompt |
| Today | daily prompt, mood selector, note composer, voice dictation, streak, partner status, Recent feed |
| Journal | encrypted entries, browsing, mood tags |
| Coach | on-device conversation, safety/crisis classifier, distilled long-term memories |
| Pulse | computed relationship state + trend, cadence/mood/consistency scores |
| Insights | mood chart (7/14/30), stat tiles, mood mix, love-language reflection, high/low days |
| Grow | on-device weekly reflection, 7-day challenge, milestones & anniversaries, link to Insights |
| Pairing | link / QR / 6-digit code, waiting room, nudges, 72-hour solo fallback |
| Settings | name, reminders, export (markdown), encryption info, subscription, sync status, reflection consent, delete all data |
| Safety | crisis detection with a support banner |
| Extras | local notifications, paywall (simulated), demo seed for screenshots, home/lock-screen friendly |

## 4. Tech stack & architecture

- **Native iOS, SwiftUI + SwiftData**, deployment target **iOS 17+**.
- **Local-first / offline.** Everything works with no network.
- **No analytics, no third-party SDKs, no ads, no accounts.**
- Encryption: `CryptoService` + `SecureContent` (key lives in the device Keychain).
- The Xcode project (`Tether.xcodeproj`) is **generated** by `make_xcodeproj.py`,
  which globs `Tether/*.swift`. After adding or renaming any Swift file you must
  re-run it, or the file won't be in the target.
- Backend is behind a `SyncService` protocol — `LocalSyncService` is the default,
  `CloudKitSyncService` is ready but off (`Persistence.useCloudKit = false`).
- AI is behind a seam too: `CoachEngine.respond` (on-device today) and
  `RemoteReflectionProvider` (optional, anonymized only).

## 5. File map (`TetherApp/Tether/`)

| File | Role |
|---|---|
| `TetherApp.swift` | entry point, SwiftData container, root routing |
| `Models.swift` | SwiftData models + enums (tracks, mood, pulse, love languages) |
| `Store.swift` | session state, streaks, pairing service |
| `Theme.swift` | colour, type, spacing, gradients, motion, `tetherAppear` |
| `Components.swift` | cards, buttons, haptics, mood selector, milestone toast |
| `TetherIcons.swift` / `TetherArt.swift` | icon set and decorative art |
| `HomeViews.swift` | Today screen + Settings |
| `JournalView.swift` | journal |
| `CoachViews.swift` / `CoachModels.swift` / `CoachEngine.swift` | coach + memory |
| `PulseViews.swift` | relationship pulse |
| `InsightsViews.swift` | insights + Canvas mood chart |
| `GrowthViews.swift` | **Grow**: weekly reflection, challenge, milestones |
| `ReflectionService.swift` | **weekly reflection engine + consent + remote provider** |
| `SyncService.swift` | **sync protocol, local + CloudKit services** |
| `Persistence.swift` | **container factory (CloudKit-ready, local fallback)** |
| `PairingViews.swift` / `OnboardingViews.swift` | pairing + onboarding |
| `MainTabView.swift` | 5-tab shell |
| `PaywallView.swift` / `Purchases.swift` | subscription (simulated) |
| `Content*.swift` | wisdom-path content libraries |
| `Safety.swift`, `CryptoService.swift`, `NotificationService.swift`, `ExportService.swift`, `VoiceInput.swift`, `DemoSeed.swift`, `SplashView.swift` | supporting services |

## 6. Data model (SwiftData)

`UserProfile`, `JournalEntry`, `MoodLog`, `PromptReply`, `Invite`,
`RelationshipPulse`, `AIConversation`, `AIMessage`, `AIMemory`.

All attributes are CloudKit-safe by design: only `UUID / String / Int / Date /
Bool / Double`, enums stored as `String` raw values, **no `#Unique` and no
`@Relationship`** — cross-references are plain `UUID` properties
(`userID`, `ownerID`, `partnerID`).

## 7. What was added in this session

**Stability (Phase 0)**
- Fixed "Add another note" (was a no-op), pairing re-redeem guard, love-language
  Skip (no longer hardcodes "words"), removed a dead parameter, and a Coach
  send re-entrancy guard.
- Rewrote the Insights mood chart with `Canvas` — it was crashing the compiler
  ("Failed to produce diagnostic for expression").

**Beauty & retention (Phase 1)**
- `TetherHaptics` (tap / light / success) on mood picks, choices, send, save.
- Staggered spring entrance (`tetherAppear`) on Home and Insights.
- Streak-milestone celebration toast, VoiceOver label on the chart, illustrated
  empty states.

**Keyboard & pairing UX fixes**
- Settings and Redeem name fields: keyboard "Done" button + drag-to-dismiss so
  the field is never trapped behind the keyboard.
- Invite methods are now selectable: tap to choose, tap another to switch, with
  a checkmark and a gated "Continue" button.

**Backend seam (Phase 2)**
- `SyncService` protocol + `LocalSyncService` + `CloudKitSyncService`.
- `Persistence` factory: CloudKit private-database config when enabled, with an
  automatic fallback to local so the app never fails to launch.
- Settings → Sync status, entitlements template, `docs/CLOUDKIT_SETUP.md`.

**Growth (Phase 3)**
- **Grow tab**: milestones & anniversaries (first note → 50 reflections, streak
  3/7/30, connected, one month / one year together) and a **7-day connection
  challenge** (progress ring, strikethrough, haptics, restart).
- **Hybrid weekly reflection** (`ReflectionService.swift`): a real, on-device
  summary — check-in count, mood average vs last week, brightest/hardest day,
  top themes, streak. Example it produced from demo data:
  *"You checked in 8 times this week. Your mood averaged 3.9, about the same as
  last week. Tuesday was your brightest day. Monday was harder. 'tired',
  'saying', 'asked' came up most. Your streak is 11 days."*
- Optional **deeper reflection** behind an off-by-default consent toggle that
  sends **only** anonymized counts, mood averages, theme words, streak, and
  track — never entry text.
- Grow promoted to a primary tab (5 tabs: Today, Journal, Coach, Grow, Pulse);
  Insights is now one tap inside Grow.

**Launch prep (Phase 4)**
- `docs/PRIVACY_POLICY.md` + `docs/privacy.html` (publishable, contact set to
  `rupeshjat5@gmail.com`), `docs/HOSTING.md`, `docs/COMMANDS.md`.
- `PrivacyInfo.xcprivacy` (no tracking, no collection, UserDefaults `CA92.1`),
  shipped as a bundle resource.
- Five App Store screenshots at 6.9″ in `AppStore/Screenshots/`.

## 8. Known gaps / not done

- **CloudKit is off** until a paid Apple Developer team + iCloud capability is
  added (the entitlement must come from a real provisioning profile, otherwise
  the app won't launch on device).
- **Coach AI is on-device/simulated.** No Claude/OpenAI/Gemini key is wired;
  `RemoteReflectionProvider` has an endpoint slot but it's empty.
- **Purchases are simulated** — RevenueCat not connected.
- **No widget** (needs an App Group entitlement → paid account).
- **No unit test target** — `docs/SampleUnitTests.swift` is a reference only and
  is intentionally not compiled into the app.
- Partner-to-partner sharing is still the local invite flow; a true shared space
  needs the backend.

## 9. Ready-to-paste prompt for another AI

> Here is a SwiftUI + SwiftData iOS app called **Tether** — a private,
> one-minute-a-day check-in app for couples, inclusive of four wisdom paths
> (Secular, Biblical, Vedic, Quranic) chosen **per partner**. It is local-first,
> offline-capable, has no accounts and no analytics, and encrypts entries with a
> device-only key.
>
> The full brief is in `docs/HANDOFF_BRIEF.md` (what it does, feature inventory,
> architecture, file map, data model, known gaps). Source is in
> `TetherApp/Tether/`. The Xcode project is generated by `make_xcodeproj.py` —
> re-run it after adding or renaming any Swift file.
>
> Please review the code and give me:
> 1. **Correctness / robustness** issues — crashes, SwiftData pitfalls,
>    concurrency problems, accessibility gaps.
> 2. **New feature ideas** that fit the product (privacy-first, interfaith-inclusive,
>    one-minute-a-day). Prioritise by impact vs effort.
> 3. **Specific UI/UX improvements** — concrete SwiftUI changes to make it feel
>    warmer, calmer, and more uplifting, respecting the existing design system in
>    `Theme.swift` and `Components.swift` (warm neutrals, rounded shapes, soft
>    shadows, gentle spring motion, `TetherHaptics`).
> 4. Concrete, file-by-file diffs for your top three suggestions.
>
> Do not suggest adding analytics, ads, third-party SDKs, or anything that sends
> the user's journal text off-device — privacy is the product.
