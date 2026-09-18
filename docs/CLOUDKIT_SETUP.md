# Connecting Tether to a backend (Phase 2)

Tether is local-first. This document explains the recommended first backend —
**Apple CloudKit** — and the exact Xcode steps to turn it on. It is free, private,
and needs almost no server code because SwiftData mirrors to CloudKit for you.

## Why CloudKit first?
- **Cost:** $0. Your users' data lives in their own private iCloud; you run no server.
- **Privacy fit:** entries are already sealed with a device-only key
  (`SecureContent` / `CryptoService`) before they are stored, so even Apple cannot
  read them.
- **Effort:** ~0 lines of networking code. Flip one flag, enable a capability.
- **Escape hatch:** everything talks to a `SyncService` protocol, so a
  cross-platform backend (Supabase, a custom server) can be added later without
  touching any view.

## What is already done
- `SyncService.swift` — `SyncService` protocol + `LocalSyncService` (current
  behaviour) + `CloudKitSyncService` (account-state reporter).
- `Persistence.swift` — builds the `ModelContainer`, wired for CloudKit with a
  safe **fallback to local** if CloudKit cannot initialize.
- `TetherApp` injects the active `SyncService` into the environment.
- `SettingsView` shows the sync state (this device only / iCloud / sign-in needed).
- `Tether.entitlements` — template file (not yet attached to the target).

The app still builds and runs **local-only** because `Persistence.useCloudKit`
is `false`. Nothing breaks until you opt in.

## Turn it on (Xcode steps)
1. Open `TetherApp.xcodeproj`.
2. Select the **Tether** target → **Signing & Capabilities**.
3. Ensure a **Team** is selected (your Apple ID / org). CloudKit needs a paid
   or free Apple Developer account; on a free account the container is
   development-only, which is fine for testing.
4. Click **+ Capability** → **iCloud** → enable **CloudKit**.
5. Under the iCloud capability, add a **Container** named `iCloud.Tether`
   (must exactly match `Persistence.cloudKitContainerID`).
6. In the same capability, the entitlement
   `com.apple.developer.icloud-container-identifiers` should now list
   `iCloud.Tether`. (Optionally attach `Tether.entitlements` to the target's
   "Signing" → "Entitlements File" field; Xcode usually creates its own when you
   add the capability — if so, just make sure the container id matches.)
7. Open `Persistence.swift` and set `static let useCloudKit = true`.
8. Build & run on a device signed into iCloud. Settings → **Sync** should flip
   from "This device only" to "iCloud". Your journal now syncs across the user's
   devices automatically.

## Notes / gotchas
- **Simulator:** CloudKit works in the simulator but uses the simulator's iCloud
  identity; prefer a real device for the first end-to-end check.
- **Schema:** CloudKit requires every synced model to be compatible — no
  `#Unique`, relationships need inverses. Tether's models use plain `UUID`
  references and `String` raw-value enums, so they are already compatible. If you
  add a model later, keep those rules or the container will fail to initialize
  (we then fall back to local; check the Xcode console for the CloudKit error).
- **Sharing between two partners:** CloudKit `private` databases are per-Apple-ID.
  Pairing two people still needs the existing invite/code flow (or a future
  `shared` CloudKit zone / Supabase). Phase 2 only syncs a single user's data
  across their own devices.
- **Cross-platform later:** implement `SyncService` for Supabase and swap it in
  `TetherApp.init()`. Views never reference CloudKit directly.

## Free alternatives (if CloudKit does not fit)
- **Supabase** (free tier: 500 MB DB, Auth, Realtime) — best when you need
  web/Android or two partners on different Apple IDs to share data.
- **Firebase** (Spark free tier) — Realtime DB + Auth, broad platform support.
- **CloudKit + a small Supabase layer** — CloudKit for personal sync, Supabase
  for the shared couple space.
