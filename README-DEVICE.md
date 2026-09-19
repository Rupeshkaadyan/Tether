# Testing Tether on a real iPhone

## The short version

| What you want | Free account | Paid account ($99/yr) |
|---|---|---|
| Run it on **your own** iPhone | ✅ | ✅ |
| Run it on a **second** iPhone (yours) | ✅ via USB | ✅ |
| **Send** someone an `.ipa` | ❌ **impossible** | ✅ |
| TestFlight | ❌ | ✅ |
| App Store | ❌ | ✅ |
| CloudKit sync (two devices) | ❌ | ✅ |

## Why a free account cannot produce a shareable IPA

Apple's free personal team issues a provisioning profile that is:

- **Locked to specific device UDIDs** — the ones you have connected
- **Valid for 7 days**, then it stops launching
- **Not eligible for ad-hoc or App Store distribution**

So even if you build an `.ipa`, iOS on a different phone will refuse to install
it. This is enforced by Apple, not by the tooling. There is no workaround, and
anything claiming otherwise is either a paid account or a sideloading service
that will get your Apple ID banned.

## ✅ What actually works: test on a second iPhone via USB

If the second phone can be plugged into **this Mac**, you can install on it
with a free account. No IPA required.

1. `cd TetherApp && python3 make_xcodeproj.py`
2. Open `Tether.xcodeproj` in Xcode
3. Select the **Tether** target → **Signing & Capabilities**
4. **Team** → your **Personal Team**
5. Plug the second iPhone in with a cable
6. On the iPhone: **Trust This Computer**
7. In Xcode's toolbar, pick that iPhone as the run destination
8. Press **⌘R**

Xcode signs the app for that device and installs it. It will run for **7 days**,
after which you re-run step 8 to refresh it.

> ⚠️ Free accounts can only register a small number of devices. If Xcode
> complains, open **Window → Devices and Simulators** and check the device is
> listed and trusted.

## ⚠️ Before you install: delete the old copy

Tether has gained new data models since you last installed it. If you install
over an existing copy, SwiftData may fail to open the old store.

**Delete Tether from the phone first**, then install.

## When you get the paid account

Everything is ready. Two commands:

```bash
cd TetherApp
TEAM_ID=ABCDE12345 ./make_ipa.sh ad-hoc
```

`make_ipa.sh` archives, exports and tells you where the `.ipa` landed. Use
`app-store` instead of `ad-hoc` to prepare an App Store upload.

Then, in order:

1. Register your partner's iPhone's UDID in the developer portal (for ad-hoc)
2. Or upload to **TestFlight** — this is the better route, because it needs no
   cables and no UDIDs
3. Flip `Persistence.useCloudKit = true` to enable two-device sync
4. Follow `docs/GO_LIVE.md`

## What each step unlocks

| Step | What it gives you |
|---|---|
| Paid account | An IPA you can actually send |
| TestFlight | Your partner installs from the App Store app, no cable |
| CloudKit on | **The two of you, on two phones, for real** |

That last one is the whole point of Tether. Everything up to it is a very
polished single-player experience of a two-player idea.
