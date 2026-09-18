# Tether — command reference

Everything you need to run, verify, and ship. Run from the `TetherApp/` folder
unless noted. Replace `<UDID>` with a simulator ID from
`xcrun simctl list devices available`.

---

## Git

```bash
# Save and push work
git add -A && git commit -m "Describe the change" && git push origin main

# Check what is unpushed
git log --oneline origin/main..HEAD

# Current status
git status --short
```

Remote: `https://github.com/Rupeshkaadyan/Tether.git` (branch `main`).

---

## Build & run (no Xcode GUI needed)

```bash
# 1. Regenerate the project — REQUIRED after adding/renaming any .swift file
python3 make_xcodeproj.py

# 2. Build for the simulator
xcodebuild -project Tether.xcodeproj -target Tether -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build

# 3. Boot a simulator and install
xcrun simctl boot <UDID>
xcrun simctl bootstatus <UDID> -b
xcrun simctl install <UDID> build/Debug-iphonesimulator/Tether.app

# 4. Launch (options: -seedDemo fills demo data; -tab-X opens a tab)
xcrun simctl launch <UDID> com.tethercouples.app -seedDemo
xcrun simctl launch <UDID> com.tethercouples.app -seedDemo -tab-grow

# 5. Screenshot and confirm it is still alive
xcrun simctl io <UDID> screenshot out.png
kill -0 <PID>          # PID is printed by the launch command
```

**Tip:** if screenshots start coming back blank or showing the home screen,
the simulator needs a reset:

```bash
xcrun simctl shutdown <UDID>; xcrun simctl boot <UDID>
```

---

## Turn on iCloud sync (optional, needs a paid Apple Developer team)

1. Open `Tether.xcodeproj` → **Signing & Capabilities** → select your Team.
2. **+ Capability → iCloud → CloudKit** → container `iCloud.Tether`.
3. Then flip the flag:

```bash
sed -i '' 's/static let useCloudKit = false/static let useCloudKit = true/' \
  Tether/Persistence.swift
```

Without step 2 the app builds but will not launch — the iCloud entitlement has
to come from a real provisioning profile.

---

## Point the deeper reflection at your proxy (optional)

```bash
# On a simulator
xcrun simctl spawn booted defaults write com.tethercouples.app \
  tether.reflection.endpoint "https://your-proxy.example.com/reflect"

# On a Mac (for a scheme argument / device build)
defaults write com.tethercouples.app tether.reflection.endpoint "https://..."
```

Then enable **Settings → Weekly reflection → Deeper reflections** in the app.
The endpoint receives only anonymized counts, mood averages, theme words,
streak length, and the wisdom track — never entry text.

---

## Host the privacy policy (free)

Contact email is already set to `rupeshjat5@gmail.com` in `docs/privacy.html`
and `docs/PRIVACY_POLICY.md`.

```bash
# GitHub Pages
mkdir ~/tether-legal && cp docs/privacy.html ~/tether-legal/index.html
cd ~/tether-legal && git init && git add index.html \
  && git commit -m "Tether privacy policy"
gh repo create tether-legal --public --source=. --push
gh api -X POST /repos/Rupeshkaadyan/tether-legal/pages \
  -f source[branch]=main -f source[path]=/
# → https://rupeshkaadyan.github.io/tether-legal/
```

No `gh` CLI? Do it in the browser instead — full steps are in
`docs/HOSTING.md` (also covers Netlify Drop and Cloudflare Pages).

Then paste the live URL into **App Store Connect → App Information →
Privacy Policy URL**.

---

## Submit to TestFlight

The project has no shared scheme, so use Xcode for the upload:

1. Xcode → **Product → Archive** (select your Team when prompted).
2. **Window → Organizer** → pick the archive → **Distribute App**.
3. Choose **TestFlight & App Store** → **Upload**.
4. In **App Store Connect → TestFlight**, add your own email as an internal
   tester and install via the TestFlight app.

Command-line equivalent once a scheme exists:

```bash
xcodebuild -project Tether.xcodeproj -scheme Tether -configuration Release \
  -archivePath build/Tether.xcarchive archive
```

---

## Quick checks

```bash
# Confirm the privacy manifest ships inside the app
plutil -p build/Debug-iphonesimulator/Tether.app/PrivacyInfo.xcprivacy

# Scan the simulator log for errors
xcrun simctl spawn booted log show --last 30s \
  --predicate 'process == "Tether"' --style compact

# List simulators
xcrun simctl list devices available
```
