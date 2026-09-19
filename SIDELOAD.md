# Sharing Tether without the $99 — the sideload route

## The idea

An **unsigned IPA** has no Apple signature. A sideloading tool on the other
iPhone signs it **with that person's own free Apple ID**, on their device.

So: you build once, send one file, and each person signs it themselves. No
paid account, no cables, no UDIDs.

This is legitimate. Apple explicitly permits free-account development signing.
Tether is your own app, so you are not circumventing anything.

## What you need

| | |
|---|---|
| **The file** | `build/Tether-unsigned.ipa` (1.7 MB) |
| **On the other iPhone** | AltStore or SideStore |
| **A computer** | AltStore needs AltServer running once on a Mac/PC. SideStore needs it only for the initial setup, then it is standalone |

## Steps

### 1. Send the IPA

AirDrop `Tether-unsigned.ipa` to the other iPhone, or put it in iCloud Drive /
Files. It will land in **Files → Downloads**.

### 2. Install a sideloading tool on that iPhone

- **SideStore** — better long term, standalone after setup.
  `sidestore.io`
- **AltStore** — simpler to set up, but needs AltServer running on a computer
  on the same Wi-Fi to refresh. `altstore.io`

### 3. Sign and install

1. Open AltStore / SideStore on the iPhone
2. **+** → choose `Tether-unsigned.ipa` from Files
3. Sign in with **that person's own Apple ID** (a free one is fine)
4. It signs and installs. Tether appears on the Home Screen.

### 4. Trust the developer

**Settings → General → VPN & Device Management → [their Apple ID] → Trust**

Then open Tether.

## ⚠️ The honest caveats

| Caveat | Detail |
|---|---|
| **7-day expiry** | Free signing lasts 7 days. After that the app stops opening and must be re-signed. SideStore/AltStore can refresh automatically if left running |
| **3 apps at a time** | A free Apple ID can have 3 sideloaded apps |
| **10 app IDs per week** | Signing repeatedly can hit this limit |
| **Each person signs their own** | Your partner uses **their** Apple ID, not yours |
| **No CloudKit** | Two-phone sync still needs the paid account. Each phone has its own data |

## What this gets you

✅ The real app, on a second iPhone, free
✅ Your partner can feel the interface, the landscape, the ritual
✅ Each of you can write entries and use every single-device feature

❌ **The two of you will not see each other's entries.** That is CloudKit, and
CloudKit is the paid step. This is the one thing sideloading cannot work around.

## If that last line is a dealbreaker

It is the whole product. Tether's entire premise is two people seeing each
other's answers.

So the honest recommendation: **use sideloading to show your partner the app
and get their reaction.** If they love it — and they probably will — then the
$99 is no longer a leap of faith. It is the obvious next step.

## For when you have the account

```bash
TEAM_ID=ABCDE12345 ./make_ipa.sh app-store   # or ad-hoc
```

Then **TestFlight**, which replaces all of the above with a single link that
never expires.
