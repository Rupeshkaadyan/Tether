# Go live: CloudKit + TestFlight in ~10 minutes

Everything on the code side is already done and sitting behind one flag.
This doc is the exact sequence for the day you have a paid Apple Developer
account.

## Current state (already prepared)

| Thing | Where | Value |
|---|---|---|
| CloudKit flag | `Tether/Persistence.swift:10` | `false` (safe default) |
| Container ID | `Tether/Persistence.swift:14` | `iCloud.Tether` |
| Entitlements file | `Tether/Tether.entitlements` | already contains `iCloud.Tether` |
| Fallback | `Persistence.make()` | falls back to local store if CloudKit can't init — **never crashes** |
| Sync UI | Settings → Sync | shows local-only / iCloud / sign-in needed |

You do **not** need to write any code. Only one line changes.

---

## Step 1 — Get the account (you, ~10 min)

Enrol at **developer.apple.com/programs** — $99/year.
Approval is usually instant for individuals, occasionally a day or two.

This one purchase unblocks: real two-device sync, TestFlight, and
subscriptions.

## Step 2 — Enable the capability (Xcode, ~2 min)

1. Open `Tether.xcodeproj`.
2. Select the **Tether** target → **Signing & Capabilities**.
3. Under **Team**, pick your paid team (not your personal free team).
4. Click **+ Capability** → choose **iCloud**.
5. Tick **CloudKit**.
6. Under **Containers**, add: `iCloud.Tether`
   (must match `Persistence.cloudKitContainerID` exactly).
7. Xcode writes the entitlement for you. The existing
   `Tether/Tether.entitlements` already matches, so nothing should conflict.

## Step 3 — Flip the flag (30 seconds)

In `Tether/Persistence.swift`, line 10:

```swift
static let useCloudKit = true
```

That's the entire code change.

## Step 4 — Rebuild the project (~30 sec)

The `.xcodeproj` is generated. Run:

```bash
cd TetherApp
python3 make_xcodeproj.py
```

Then build in Xcode (or via `COMMANDS.md`).

## Step 5 — Test on a REAL DEVICE (important) ⚠️

**Do not judge this by the simulator.** With iCloud entitlements under ad-hoc
signing, the iOS Simulator can refuse to launch the app entirely — you'll see
it install but never appear, or it fails at launch. That is a simulator
signing limitation, **not a bug in Tether**.

Plug in an iPhone signed into iCloud and run there.

What to check:
- App launches normally
- Write an entry
- Settings → Sync should read **iCloud** (not "This device only")
- Install on a second device with the same Apple ID → the entry appears

## Step 6 — TestFlight (~5 min)

1. Xcode → **Product → Archive**
2. **Window → Organizer** → pick the archive → **Distribute App**
3. **TestFlight & App Store** → **Upload**
4. App Store Connect → **TestFlight** → add yourself (and your partner) as
   internal testers
5. Install via the TestFlight app

---

## If something goes wrong

| Symptom | Cause | Fix |
|---|---|---|
| Won't launch in simulator | iCloud entitlement not granted for ad-hoc signing | **Test on a real device** — expected behaviour |
| Builds but Settings says "This device only" | Flag still `false`, or capability missing | Confirm step 2 + step 3 |
| "Sign in to iCloud" | Device not signed into iCloud | Settings → sign in |
| Data not appearing on device 2 | Different Apple ID, or first sync still pending | Same Apple ID; wait a minute, background sync can lag |
| Xcode complains about entitlements conflict | Xcode created its own entitlements file | Keep Xcode's; the values should match anyway |

---

## After this

Once sync is real, these become possible in order:
1. Real two-person pairing (the Reveal Moment now has real data behind it)
2. RevenueCat for actual subscriptions
3. App Store submission

The pairing UI, Reveal Moment, and conflict/safety handling all already
expect real data — no rework needed when CloudKit turns on.
