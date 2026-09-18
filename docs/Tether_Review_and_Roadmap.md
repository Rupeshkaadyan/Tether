# Tether — Code Review, Roadmap & Implementation Plan

*Prepared after the app builds and runs clean. Scope: local-first iOS SwiftUI app
(`TetherApp/Tether/*.swift`), SwiftData persistence, AES‑GCM + Keychain encryption,
simulated backend / Claude / RevenueCat seams. All fixes below are intended to be
applied via Xcode's AI tools; exact file references are given.*

---

## 1. Code review — bugs, edge cases, quality

### 1.1 Functional bugs (fix first)

| # | Severity | Location | Problem | Suggested fix |
|---|----------|----------|---------|---------------|
| B1 | Medium | `HomeViews.swift` → `answeredToday` | The **"Add another note"** button only does `reply = ""`, but the text field lives in the `composer` branch which is hidden once `todayAnswered` is true. The button is a visible no‑op. | Add `@State private var showComposer = false`. Change the body condition to `if todayAnswered && !showComposer { answeredToday } else { composer }`, and have the button set `showComposer = true`. The existing composer already inserts a second entry. |
| B2 | Low | `PairingViews.swift` → `PairingService.redeem` | Redeeming a second code while already paired silently creates a **second partner** and overwrites `partnerID`. | Guard: if `me.partnerID != nil` and the existing partner is still valid, ignore or surface "Already paired". |
| B3 | Low | `OnboardingViews.swift` → `LoveLanguageStep.questionView` "Skip" | Skip hardcodes `result = .words` instead of letting the user proceed without a result. | Treat skip as "no preference yet" → `onNext()` without writing to `LoveLanguageStore`, and let Settings show the "Take the quiz" CTA. |
| B4 | Low | `InsightsViews.swift` → `InsightsView.highlightRow` | The `mood: Int` parameter is computed and passed but never used. | Either drop the parameter or actually tint the row by mood. |

### 1.2 Edge cases & robustness

- **Crypto failure path** (`CryptoService` / `SecureContent.read`): if the keychain key is missing or ciphertext is corrupt, `read` must fail *gracefully* (return a localized placeholder) rather than crash on decode. Add a `do/catch` and surface "Unable to decrypt this entry."
- **Empty / single‑day data** in Insights: already handled (empty state + `guard !points.isEmpty`). Good. But `distribution` with zero entries divides by `max(...,1)` — safe.
- **Re‑entrancy in `CoachView.send()`**: rapid taps could double‑send. Guard with `guard !isThinking else { return }` at the top (currently `canSend` checks `!isThinking` but the button is only disabled, not the async path).
- **Backgrounding during onboarding**: progress is only persisted at each step; if the app is killed mid‑flow, the user restarts onboarding. Acceptable for v1, but consider autosaving `onboardingStep`.
- **Delete‑all** (`SettingsView.deleteEverything`) purges data but not the `UserProfile` itself, and does not reset `SessionStore.profile` — the UI keeps showing the same name with empty data. Intended, but verify the home screen degrades gracefully (it does).

### 1.3 Code quality

- **Tests**: none. Add a `TetherTests` target with unit tests for `PulseEngine.compute`, `SafetyClassifier.classify`, `Streaks.current`, and `LoveLanguageQuiz.result`. These are pure functions — cheap, high‑value.
- **Magic numbers**: `window` 7/14/30, free‑message cap 5, streak "yesterday" tolerance — extract to a `TetherConfig` struct so they're tunable.
- **Duplicate mood storage**: `JournalEntry.mood` and `MoodLog.mood` both exist (entry = content, log = trend). This is intentional but worth a one‑line comment so future editors don't "dedupe" it and break the Pulse.
- **Accessibility**: the Insights chart (`Canvas`) has no `accessibilityLabel`/`accessibilityValue`. VoiceOver users get nothing. Add `.accessibilityLabel("Mood trend over \(window) days, average \(avgMoodValue ?? 0, specifier: "%.1f")")` and `.accessibilityHidden(false)` on the Canvas.
- **`MainTabView.label` overload**: two `label` functions (one `TetherIcon`, one `String`). Works, but rename the SF‑Symbol one to `systemLabel` to avoid any ambiguity for the compiler or future readers.

---

## 2. Prioritized next‑steps roadmap

| Priority | Theme | Items | Why |
|----------|-------|-------|-----|
| **P0** | Stability | B1–B4, crypto graceful‑fail, send re‑entrancy guard | Cheap, removes visible/likely crashes before any growth work. |
| **P1** | Trust & retention | Unit tests, accessibility labels, micro‑interactions (streak milestone celebration), richer empty states | Turns a working prototype into something users keep. |
| **P2** | Real backend | CloudKit sync (or Supabase), real RevenueCat, real Claude API | Moves from "simulated" to "live" without rebuilding the UI. |
| **P3** | Growth features | Shared Pulse, milestones, couples challenges, AI weekly summary, widgets | Differentiation + stickiness. |
| **P4** | Launch | App Store assets, privacy policy, TestFlight, privacy‑first analytics | Ship. |

Sequencing is **strictly cumulative**: do not start P2 until P0/P1 land, because a live backend amplifies any local bug.

---

## 3. Free backend / cloud storage options

> The single highest‑leverage move: **keep SwiftData, switch the store to a CloudKit‑backed container** (`NSPersistentCloudKitContainer`). Apple syncs the *exact same* SwiftData models across the user's devices, end‑to‑end encrypted, **at zero cost**. Almost no new code; pairing becomes a CloudKit share or a Supabase invite.

| Service | Free tier | Best for | Notes |
|---------|-----------|----------|-------|
| **Apple CloudKit** | Free, private, E2E | 1st choice for an Apple‑only, privacy‑first app | Pairing = CloudKit share; no servers to run. |
| **Supabase** | 500 MB DB, 1 GB files, Auth, Realtime | Cross‑platform (web/Android) later | Postgres + Row Level Security; good if you outgrow CloudKit. |
| **Firebase (Spark)** | Firestore 1 GB, Auth, FCM | Google ecosystem, push at scale | Less private‑by‑default; more config. |
| **Appwrite** | Free cloud tier + self‑host | OSS, Supabase alternative | |
| **PocketBase** | Open‑source, 1 binary, self‑host | Tiny footprint, simple | You run the server. |
| **AWS Amplify** | 12‑mo free + free DynamoDB | If already on AWS | Heaviest to operate. |

**Recommendation**: start with **CloudKit** for zero‑cost private sync; design the data layer behind a `SyncService` protocol so you can later swap in Supabase for cross‑platform without touching views.

---

## 4. New feature ideas

- **Shared Pulse** — privacy‑preserving aggregate of both partners' weeks (e.g., "You're both drifting — here's a 5‑minute reconnect prompt").
- **Milestones & anniversaries** — auto‑track "first entry," "30‑day streak," relationship dates; gentle reminders.
- **Couples challenges** — 7‑day kindness / gratitude / date‑night challenges with shared progress.
- **Guided conversations** — structured prompts for tricky topics (money, chores, family) from each wisdom track.
- **AI weekly summary** — Claude condenses the week's journal into one reflective note (needs real API).
- **Voice notes playback** — you already capture voice; let users replay the transcribed moment.
- **Home & Lock Screen widgets** — today's prompt + streak at a glance.
- **Gratitude thread** — a lightweight shared "what I appreciated about you" log.
- **Conflict‑cooldown mode** — a breathing/grounding session when mood logs are low for several days.

---

## 5. Colorful, uplifting UI/UX

Keep the existing warm‑paper aesthetic; push it further so the app *feels* like a calm, happy ritual:

- **Palette**: warm coral/peach (energy), sunflower amber (joy), sage green (growth/thriving), soft lavender (calm), sky blue (trust). Use the existing `TetherColor` adaptive system so dark mode stays cozy, not clinical.
- **Motion**: the `BreathingOrb` is a great start — extend it to streak‑milestone **confetti‑lite** (a soft burst, not noisy), and spring‑scale on the Save button.
- **Illustrated empty states** (replace plain text): a tiny drawn couple/orb scene for "no entries yet," "just you for now," "invite sent."
- **Haptics**: a gentle tap on Save and on streak milestones.
- **Typography**: keep SF Rounded; increase tracking on large titles (already done) and add a touch more line‑height for breathing room.
- **Delight details**: gradient progress ring on streaks, a "today's small win" daily micro‑prompt, soft card shadows that lift on press.

---

## 6. Deep implementation plan

### Phase 0 — Stability (1–2 days, P0)
1. Fix B1 (composer reveal) — `HomeViews.swift`.
2. Fix B2 (redeem guard) — `PairingViews.swift`.
3. Fix B3 (skip = no preference) — `OnboardingViews.swift`.
4. `SecureContent.read` try/catch fallback — `CryptoService.swift`.
5. `CoachView.send()` re‑entrancy guard.
6. Rename `MainTabView.label` → `systemLabel`.

### Phase 1 — Trust & retention (3–5 days, P1)
1. Add `TetherTests`: `PulseEngine`, `SafetyClassifier`, `Streaks`, `LoveLanguageQuiz`.
2. Accessibility: chart `accessibilityLabel`, Dynamic Type pass on Insights tiles.
3. Micro‑interactions: streak‑milestone celebration, button springs, haptics.
4. Illustrated empty states for Home / Insights / Pairing.
5. Extract `TetherConfig` (caps, tolerances, windows).

### Phase 2 — Real backend (1–2 weeks, P2)
1. Introduce `SyncService` protocol; default `LocalSyncService` (current behavior).
2. Implement `CloudKitSyncService` using `NSPersistentCloudKitContainer`; migrate the SwiftData stack in `TetherApp.swift`.
3. Pairing → CloudKit share (or Supabase invite) behind the same `PairingService` API.
4. Swap `PurchaseService` → real RevenueCat (keep simulated fallback).
5. Swap `CoachEngine.respond` → real Claude API behind `CoachProvider` (keep local fallback).
6. Re‑run tests; verify offline‑first still works (CloudKit queues writes).

### Phase 3 — Growth (2–4 weeks, P3)
1. Shared Pulse aggregate + privacy gating.
2. Milestones & anniversaries.
3. Couples challenges (7‑day).
4. Guided conversations per track.
5. AI weekly summary (Claude).
6. Home/Lock Screen widgets.

### Phase 4 — Launch (1–2 weeks, P4)
1. App Store screenshots, icons, privacy policy (required for health/relationships category).
2. TestFlight beta; privacy‑first analytics (e.g., TelemetryDeck / Plausible, no PII).
3. A/B the two paywall variants already in `PaywallView`.
4. Ship 1.0.

### Effort vs impact (quick view)
- **Highest ROI now**: Phase 0 + Phase 1 tests/accessibility — low effort, directly improves the experience you can already ship.
- **Highest risk**: Phase 2 backend — do it behind protocols so the UI never blocks.
- **Highest differentiation**: Phase 3 Shared Pulse + challenges.

---

### Suggested Xcode AI prompts (copy‑paste)
- *"In HomeViews.swift, make the 'Add another note' button reveal the composer instead of only clearing the draft."* (B1)
- *"Add a unit test target TetherTests and tests for PulseEngine.compute, SafetyClassifier.classify, and Streaks.current."* (P1)
- *"Refactor the SwiftData stack in TetherApp.swift to use NSPersistentCloudKitContainer behind a SyncService protocol, keeping local‑only as the default."* (P2)
- *"Add an accessibilityLabel to the InsightsMoodChart Canvas describing the window and average mood."* (P1)
