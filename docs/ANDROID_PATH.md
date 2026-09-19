# The Android path — an honest plan

## Read this first

Two things are true at once, and you should hold both:

**1. This will not make you money in the USA.** For a paid subscription app,
iOS users in the US spend roughly **2–3× more per user** than Android users.
US iOS share is ~55–60%, and paying subscribers skew iOS harder than that. An
Android-first launch in the US is the *lower-revenue* half of the market.

**2. It is a genuine learning play.** You will learn to ship, price, publish
and support a real product for $25. That has value — just not the value you're
picturing.

**3. It works against your stated goal.** You want to be hired as an **iOS**
developer. Months in Kotlin is months not building SwiftUI. If the career goal
is real, this is a cost, not a free option.

If you still want to do it — and there are good reasons to — here is the
honest plan.

---

## What Android actually costs

| Item | Cost |
|---|---|
| Google Play Developer account | **$25, one-time** |
| Android Studio | free |
| Emulator / your phone | free |
| Firebase (sync, free tier) | free to start |
| Privacy policy hosting | free (GitHub Pages) |
| **Total to publish** | **$25** |

No annual fee. No 7-day expiry. No UDID limits. This part is genuinely better
than Apple.

---

## The port is a rewrite

Tether is SwiftUI. There is **no converter**. Every file gets written again.

| iOS | Android |
|---|---|
| SwiftUI | **Jetpack Compose** |
| SwiftData | **Room** |
| Keychain | **EncryptedSharedPreferences / Keystore** |
| Face ID (`LocalAuthentication`) | **BiometricPrompt** |
| CloudKit | **Firebase Firestore** |
| `Canvas` / `Path` | **Compose `Canvas`** |
| UserDefaults | **DataStore** |
| `strings.xcstrings` | **`strings.xml` per locale** |
| `@Observable` | **ViewModel + StateFlow** |

The **design carries over completely** — your palettes, the landscape, the
Feel system, the typography. That's your real asset. The code does not.

---

## Scope v1 brutally

Do **not** port everything. Ship the loop that is the product:

**In v1:**
- Daily prompt (reuse your prompt library — it's just data)
- Mood + answer
- The reveal when both have answered
- Local encrypted store
- Language: English + Hindi
- The Feel toggle (Classic / Warm)
- The landscape scene

**Not in v1:** Memory Lane, year book PDF, voice notes, private chat,
gratitude thread, rituals, warmth signals, insights, coach.

You can add those once real people are using it. Porting all of it before
anyone has used it is how the project dies.

---

## Suggested sequence

**Week 1 — Learn the basics**
- Android Studio, Kotlin syntax, Compose fundamentals
- Build a throwaway screen: a list, a text field, a button
- Do not start Tether yet

**Week 2 — Data layer**
- Room entities mirroring `JournalEntry`, `UserProfile`
- EncryptedSharedPreferences for the key
- A repository layer

**Week 3 — The core loop**
- Prompt screen, mood selector, answer field
- Save to Room
- The reveal screen

**Week 4 — Make it look like Tether**
- Port the palette and typography
- Compose `Canvas` for the landscape and the slack curve
- The Feel toggle

**Week 5 — Ship**
- Google Play Console: listing, screenshots, content rating
- Privacy policy URL (required)
- Internal testing → closed testing → production
- Note: **new personal accounts must run a closed test with 12+ testers for
  14 days before production.** Plan for that delay.

---

## Monetisation

- **Google Play Billing**, subscription
- Price for the US: **$4.99–7.99/month**, or ~$39.99/year
- Google takes 15% (under $1M revenue), not 30%
- Offer a real free tier — the daily loop free, depth paid

**Be realistic:** with no marketing, organic revenue on either store is close
to zero. The store does not bring users. You bring users.

---

## The market you're targeting

You said USA and high-value countries. Honest read:

| Market | Reality |
|---|---|
| **USA** | Highest value, but Android is the minority and spends less |
| **UK / Canada / Australia** | Same shape as the US |
| **Germany / Nordics** | Android stronger, decent spend |
| **India** | Huge Android base, very low willingness to pay for this category |

If revenue is the goal, the US Android segment is the **worst** of the
high-value markets to start in — it's the smaller, lower-spending half.

---

## What I would actually do

**If the goal is money:** don't build Android Tether. Save for the $99. Two
subscribers cover it. Ship where the paying users already are.

**If the goal is learning to ship:** build a **different, small Android app**
first. Something you can finish in two weeks. Learn Play Console, billing,
and ratings on something disposable. Then decide whether to port Tether.

**If the goal is Tether on Android specifically:** do the scoped v1 above, and
accept it's a labour of love, not a revenue plan.

---

## The one thing that decides everything

**Distribution.**

Neither store will hand you users. The question that matters is not $25 vs
$99 — it is:

> How will the first 100 couples find this?

Answer that and either platform works. Fail to answer it and neither does.
