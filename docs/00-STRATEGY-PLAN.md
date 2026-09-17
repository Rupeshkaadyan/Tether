# SĀTHI — Complete Product & Execution Plan
### USA-First · Global-Ready · Build-Ready

---

# PART 0 — THE STRATEGIC CALL: WHY USA-FIRST IS CORRECT

You said main focus is USA. **That is the right decision, and it's not close.** Here's the math, using real 2026 benchmark data:

| Metric | USA | India |
|---|---|---|
| Freemium → paid conversion | **3–5%** | 0.5–2% |
| Sustainable annual price point | **$69–$99** | ₹799–₹999 (~$9–12) |
| Revenue from 100,000 users | **~$280,000/yr** | ~$11,000/yr |
| Relative revenue per user | **1×** | **~0.04×** |

**Same product, ~25× the revenue per user in the USA.** India is a volume game that requires millions of users before it pays. The USA is a value game that pays at 100k users.

### The reframe that makes USA-first even stronger

You originally framed the multi-wisdom-track idea as a play for **India** (Hindu/Muslim/Christian/secular). Flip it:

> **The USA has the highest interfaith marriage rate on earth.** Roughly 4 in 10 American marriages cross religious lines, and ~30% of US adults are religiously unaffiliated. Add large Muslim, Hindu, Jewish, Buddhist, and Sikh populations.

**Your "Choose Your Wisdom" feature is a MORE powerful US differentiator than an India one.** In India most marriages are same-faith — the feature is nice-to-have. In the USA, interfaith and mixed-belief couples are the mainstream, and **no competitor serves them.** Paired, Lasting, Couply, Evergreen, Relish, Twogle — every single one is secular-generic or implicitly Christian. None let a Hindu-Muslim or Christian-atheist couple see themselves.

### Your positioning sentence

> **Sāthi is the relationship app for couples who don't share a single story.** Two people, two wisdom tracks, one shared practice.

That is a wedge no competitor can copy quickly, because it's a content-architecture problem, not a feature problem.

---

# PART 1 — MISTAKES TO FIX

## ❌ MISTAKE 1 — ₹499/yr India pricing is too cheap (and US pricing is unanchored)

**What's wrong:** ₹499/yr sits below the ₹799–₹999 band that actually converts in India. Worse, Indian consumers read sub-₹500 as *low quality* — the research is explicit that below ₹99/mo (~₹1,188/yr) perceived quality drops. You're leaving money on the table AND signaling cheapness. Separately, your US price of $49.99/yr is *below* every serious competitor, which under-positions a premium AI product.

**Why it matters:** Platform commission is 15–30%. At ₹499 you net ~₹350–425 before support, content, and AI inference costs. AI coaching has real per-user variable cost. The math doesn't work.

**The fix — reprice both markets:**

| Market | Monthly | Annual | Notes |
|---|---|---|---|
| **USA (primary)** | $12.99 | **$79.99** | Sits between Paired ($60–84) and Relish ($99.99). Premium but defensible with AI coach. |
| **USA — Couples+** | — | **$149.99** | Adds 2 live therapist/coach sessions per year. |
| **India (expansion)** | ₹149 | **₹899** | In the proven ₹799–₹999 conversion band. |
| **India — Couples+** | — | **₹1,799** | |
| **Rest of world** | PPP-tiered | $20–60 | Use StoreKit/Play automatic PPP tiers. |

---

## ❌ MISTAKE 2 — No "one subscription covers both partners"

**What's wrong:** Your pricing screens show per-tier pricing but don't state that **one purchase covers both people.**

**Why it matters:** This is a hard industry standard. Paired, Couply, Lasting, Relish, and Twogle **all** cover both partners under one sub. If you charge per person you instantly look 2× more expensive than you are, and the second partner becomes a drop-off point.

**The fix:** Make it a headline, not a footnote. Put **"One subscription. Both partners. Always."** on the paywall, the pricing screen, and the App Store subtitle. This is one of your cheapest conversion wins.

---

## ❌ MISTAKE 3 — Partner sync failure is still unaddressed

**What's wrong:** You correctly diagnosed the "invite screen loop" from Anchored. **Your 12 screens don't fix it.** There is no screen for "partner hasn't joined yet," no fallback, no timeout, no alternative pairing method.

**Why it matters:** This was Anchored's actual reported failure. If you ship Sāthi with the same hole, the design system won't save you. Roughly **30–40% of invitees never install** — that's not an edge case, it's the majority failure path in some cohorts.

**The fix — build a 6-screen pairing resilience suite:**

1. **Invite sent** — shows share sheet + QR code + 6-digit code (three paths, not one)
2. **Waiting room** — is it sending? *Not* a dead spinner. Show "Priya hasn't opened it yet — here's what to text her" with a copy-able message
3. **Nudge** — after 24h/72h, one-tap re-invite via WhatsApp/SMS/iMessage
4. **Fallback pairing** — QR scan in person (kills 100% of remote-link failures)
5. **Solo mode offer** — after 72h: *"Start solo. Everything you do syncs the moment she joins."* **This is the most important screen in the app.**
6. **Pairing confirmed** — a genuine celebration moment. Both partners get a push. Ritual, not just a checkmark.

---

## ❌ MISTAKES 4 — "What if my partner won't join?" has no answer

**What's wrong:** Every competitor has this flaw, and so do you. The entire app is gated behind both partners being present. **"Only works if both partners engage" is the #1 criticism of Paired, Evergreen, Couply, and Love Nudge.**

**Why it matters:** In the USA especially, one partner is usually the initiator and the other is lukewarm — studies of couples apps consistently show asymmetric enthusiasm. If lukewarm partner never joins, you lose **both** users. You're not losing one user, you're losing an account.

**The fix — ship Solo Mode as a first-class path, not a consolation prize:**
- Full single-user value: own mood tracking, own wisdom track, own journal, own growth
- "Letters to your partner" — write something they read when they join
- Visible progress that doesn't require them
- When they join, a **merge ceremony** — past entries unlock together
- Reframe: *"You can't control whether they join. You can start anyway."* This is emotionally true and it converts.

**Business impact:** Solo Mode likely doubles your addressable accounts. It is the single highest-ROI thing on this list.

---

## ❌ MISTAKE 5 — No retention loop designed

**What's wrong:** You identified "habit drop-off" as a problem. Your screens show a Couple Journal with **four free-text fields.** That's not a habit, that's homework.

**Why it matters:** Daily couple apps live or die on a 30-second ritual. Four text fields is a 4-minute commitment. It will die in week two.

**The fix — design the 60-second loop:**
- **One** prompt per day. Not four.
- **Two taps:** a 1–5 mood dot + one sentence (voice-to-text enabled)
- Answer is **hidden until both reply** (Agape's mechanic — it works, and it's free to copy)
- **Streak** with forgiving "freeze days" (harsh streaks cause abandonment)
- Smart notification timing — learn when each partner is actually active, don't blast 9am UTC
- Weekly "Relationship Pulse" recap on Sunday — the payoff moment

---

## ❌ MISTAKE 6 — AI coach is a generic chatbot

**What's wrong:** Screen 9 shows a chat window. In 2026 that's table stakes, not a moat. Any competitor ships this in a sprint.

**Why it matters:** Relish's differentiator was *human* coaching. Twogle's was *structured conflict repair*. Yours is currently nothing.

**The fix — make the coach genuinely defensible:**

| Capability | Why it's a moat |
|---|---|
| **Persistent couple memory** | Remembers what you fought about 3 weeks ago, follows up. Nobody does this. |
| **Per-partner wisdom grounding** | His advice draws on his track, hers on hers. Deeply personal. |
| **Voice mode** | Nobody types during a real disagreement. **This is critical.** |
| **De-escalation mode** | Detects both partners logging "Stressed/Angry" → auto-offers a cool-down protocol |
| **Tone shift detection** | "Priya's entries have been shorter this week" → gentle surfacing |
| **Cultural context injection** | Knows you're navigating in-law tension, not generic "communication" |

**Guardrails (non-negotiable, especially for US liability):** no diagnosis, no divorce recommendation, no crisis counseling without escalation, no manipulation, no advice that contradicts safety. Every response needs a safety classifier in front of it.

---

## ❌ MISTAKE 7 — Love Languages is built on thin science

**What's wrong:** You built a whole screen on Gary Chapman's 5 Love Languages. It's beloved and it's **weakly supported by research** — this is the documented criticism of Love Nudge, the official Love Languages app.

**Why it matters:** If you lead with it, informed US users (and press, and therapists) will dismiss you. The US market is therapy-literate.

**The fix — keep it, demote it:**
- Keep Love Languages as the **fun engagement hook** — it's delightful and it drives the "send an act of service" action loop
- **Ground core content in what actually has evidence:** Gottman Method, Emotionally Focused Therapy (EFT), attachment theory, nonviolent communication (NVC)
- Reference Gottman Card Decks (1,000+ free research-backed prompts) as a benchmarking bar for your content quality
- Never claim clinical efficacy. Ever. US regulators care.

---

## ❌ MISTAKE 8 — No safety, crisis, or escalation layer

**What's wrong:** Nothing in your 12 screens handles: domestic abuse, suicidal ideation, or "this relationship is over."

**Why it matters:** Two problems. **Ethical** — you will have users in crisis and you must not bot-handle them. **Legal** — in the USA, a wellness app giving relationship advice to a vulnerable person is a genuine liability surface. Every competitor article ends with the same caveat: *no app replaces therapy when there's contempt, abuse, addiction, or infidelity.*

**The fix — build it before launch, not after:**
- Safety classifier on **all** AI input and **all** journal text (cheap, fast, essential)
- If abuse/self-harm signals → **suppress all couple-facing output**, show one partner-only resource card
- US: 988 Suicide & Crisis Lifeline, National Domestic Violence Hotline
- India: equivalent local helplines
- A "pause the app" state — if things are bad, stop sending cheerful prompts
- Clear scope disclaimer in onboarding, ToS, and the AI screen
- **Never** show one partner's crisis signal to the other partner

---

## ❌ MISTAKE 9 — No privacy story (this is a US dealbreaker too)

**What's wrong:** You're asking couples to write their most vulnerable thoughts. There's no privacy promise anywhere.

**Why it matters:** Post-Roe USA, intimate-data apps are under real scrutiny. Indian users are privacy-wary post-Pegasus. This is now a **feature**, not a legal page.

**The fix:**
- End-to-end encryption on journal + chat (Twogle does this — match it)
- **"Your words never leave your device unencrypted"** as a paywall bullet
- No third-party analytics on journal content — ever
- Per-field "private to me" vs "shared" toggle
- Export & delete everything, one tap
- Consider: faceID-gated "private vault"

---

## ❌ MISTAKE 10 — Community in v1 is a liability

**What's wrong:** Screen 10 shows couple-to-couple community.

**Why it matters:** Anonymous couples discussing intimate problems attracts bad actors within weeks. Niche devotional apps survive this because users self-select for shared values. **A global, multi-faith community will not self-moderate** — you'll get religious friction, which is the one thing that could destroy the brand.

**The fix:** **Cut community from v1.** Ship at 100k+ users with real moderation (human + AI). Replace the v1 slot with a **moderated "shared wisdom" feed — curated quotes and prompts, zero user posting.** You get the feeling of community with none of the risk.

---

## ❌ MISTAKE 11 — Wisdom track is couple-level, not partner-level

**What's wrong:** Onboarding shows the *couple* choosing one track.

**Why it matters:** This destroys your best US differentiator. An interfaith couple doesn't share a track — that's the entire point.

**The fix — each partner chooses their own:**
- Partner A: Quranic · Partner B: Secular/Psychology
- Each gets content in their own framework
- **Shared prompts are built from the intersection** — universal psychology underneath, cultural/faith framing on top
- Add a genuine "Interfaith Bridge" module: navigating holidays, children's upbringing, family pressure, conversion questions. **No competitor has this. It is your moat.**

---

## ❌ MISTAKE 12 — Language overreach

**What's wrong:** Eight languages shown. Each needs native content, not translation.

**Why it matters:** Tamil couples finding Hindi-translated content is worse than English-only. It reads as fake.

**The fix — USA-first sequence:**
- **v1: English only.** (US market doesn't need more yet.)
- **v1.5: Spanish** — ~13% of US population, large and underserved, and Spanish is your gateway to LatAm
- **v2: Hindi** — serves Indian-American (~5M) *and* opens India
- **v3: Tamil, Telugu, Urdu** (Urdu needs full RTL support — budget it separately)
- Rule: **a language ships only when a native speaker owns its content.** No machine-translated wisdom.

---

## ❌ MISTAKE 13 — No free tier or trial strategy

**What's wrong:** Pricing screens show paid tiers only. Competitors Paired, Couply, Evergreen, Between, Agape **all have free tiers.**

**Why it matters:** No free entry = no install volume. But pure freemium in a couples app is tricky — the value is inherently two-sided.

**The fix — "freemium with a shared gate":**
- **Free forever:** solo mode, 1 prompt/week, mood tracking, first wisdom-track content, Love Languages quiz
- **Free 14-day trial of Premium** (beats the category-standard 7 days — Twogle even admits 7 is "standard rather than generous")
- **Premium unlocks:** daily prompts, full content library, AI coach, both-partner sync, unlimited journal
- One sub covers both. Trial covers both.

---

# PART 2 — WHAT TO ADD

## ➕ 1. Seven-day onboarding ritual (replace the setup wizard)
Don't do a form. Do a week.
- **Day 1** — pick your wisdom track (30 sec)
- **Day 2** — Love Languages quiz → first result
- **Day 3** — first daily prompt, solo if needed
- **Day 4** — invite partner (with the 3-path invite)
- **Day 5** — first shared entry
- **Day 6** — Relationship Pulse baseline
- **Day 7** — AI coach introduction, personalized

## ➕ 2. Re-engagement engine
- Partner dormant 4 days → gentle nudge to the active partner ("send Priya a nudge")
- Streak at risk → "freeze your streak" instead of guilt
- Win-back at day 14/30: *"Here's what you two wrote last month"* — nostalgia beats discounts
- Never send the same reminder to both partners at the same time (feels robotic)

## ➕ 3. Offline-first architecture
US users have good connectivity, but India and travel don't. Local-first reads, queue writes, conflict-free sync. This also kills a whole class of sync bugs.

## ➕ 4. Therapist directory (v2)
Not therapy delivery — **referral + booking.** High-margin, solves the safety problem by giving you somewhere to send people, and monetizes at $149/yr Couples+. Partner with BetterHelp-adjacent networks or list licensed LMFTs.

## ➕ 5. Content engine (the real asset)
Your moat is content architecture, not features. Structure content as:
```
Universal psychological core (Gottman / EFT / attachment / NVC)
        ↓
    Wisdom track layer (Secular | Vedic | Quranic | Biblical)
        ↓
  Cultural context layer (US-individualist | US-immigrant | India-joint-family | Global)
        ↓
      Language layer (en → es → hi → ta → te → ur)
```
One core, many expressions. This is how you scale to 8 languages without 8× the work.

## ➕ 6. Accessibility (US legal + quality baseline)
Dynamic Type, VoiceOver, contrast ratios, RTL readiness, reduced-motion. Your design system is beautiful — make it usable by everyone.

## ➕ 7. Analytics that don't betray trust
Track *behavior* (DAU, streak length, prompt completion, pairing success rate). Never track *content*. Say so publicly.

---

# PART 3 — WHAT TO IMPROVE

| Area | Current | Improve to |
|---|---|---|
| **Design system** | Beautiful, comprehensive | Add accessibility specs + RTL + dynamic type. It's v1-ready, now make it production-ready. |
| **Relationship Pulse** | 3 states (Thriving/Drifting/Strained) | Good — add **trend** ("you've been drifting for 2 weeks") and a **"why"** tap-through |
| **Cultural nuances** | India/USA/Global tabs | Deepen USA: boundaries & autonomy, choreload equity, financial merging, therapy stigma, **interfaith & interracial dynamics**, military/long-distance |
| **Empty states** | Present in assets | Make them *sell the value* — "Your journal will look like this" with a sample |
| **AI avatar** | Present | Consider making it culturally neutral and non-gendered by default, user-customizable |
| **Naming** | "Sāthi" | Strong — warm, pronounceable, meaningful (साथी = companion). Keep it. Consider subtitle: **"Two people. One practice."** |
| **Progress/timer** | Present | Tie to streaks and streaks to gentle accountability, not guilt |

---

# PART 4 — COMPETITIVE POSITIONING (USA)

| App | Annual | Free tier | Both partners | Their weakness | Your edge |
|---|---|---|---|---|---|
| **Lasting** | ~$180/yr | Foundations | ✅ | Expensive, buggy, cancellation complaints | Half the price, better sync |
| **Relish** | $99.99 | ❌ | ✅ | Stale product, pushy upsells, wants phone # | Modern, no phone number |
| **Paired** | $60–84 | ✅ | ✅ | Generic content | Personalized + multi-wisdom |
| **Couply** | $69.99 | ✅ (ads) | ✅ | Broad but shallow; weak-science frameworks | Evidence-grounded |
| **Evergreen** | ~$120 | ✅ | ? | Content repeats fast; paywall by day 3 | Deeper content engine |
| **Twogle** | $119.99 | ❌ (7d trial) | ✅ | Expensive, new, unknown | 14-day trial, better price |
| **Love Nudge** | Free | ✅ | ❌ | Love Languages only, thin science | Full product |
| **Between** | $26.99 lifetime | ✅ | ❌ | Logistics only, no growth | Actual development |
| **SĀTHI** | **$79.99** | ✅ + 14d trial | ✅ | — | **Only app for interfaith/multi-wisdom couples** |

**Your one-line differentiator:** *Every other app assumes you share a worldview. Sāthi is built for when you don't.*

---

# PART 5 — MVP SCOPE v0.1 (USA)

### Build this
1. Onboarding: wisdom track (per partner) + Love Languages quiz
2. **Solo mode** (full value, no partner required)
3. **Pairing suite** — QR + link + code + waiting room + 72h solo fallback
4. **Daily prompt loop** — one prompt, mood dot, one sentence, hidden-until-both
5. **Couple journal** — simplified (mood + 1 line, not 4 fields)
6. **Relationship Pulse** + weekly recap
7. **AI coach v1** — persistent memory, voice input, safety classifier, wisdom-grounded
8. **Content library** — 90 days of prompts minimum, 2 wisdom tracks (Secular + Biblical), US cultural context
9. **Paywall** — free tier + 14-day trial + $79.99/yr, one sub covers both
10. **Safety layer** — crisis detection + US helplines
11. **Privacy** — E2E encryption on journal/chat, clear promise

### Cut from v1
- ❌ Community
- ❌ Spanish / Hindi / all localization
- ❌ India pricing + UPI (build the hook, flip it on at v1.2)
- ❌ Therapist directory
- ❌ Cultural modules beyond US
- ❌ Games, quizzes beyond Love Languages
- ❌ Apple Watch / widgets

---

# PART 6 — TECH ARCHITECTURE (recommendation)

| Layer | Recommendation |
|---|---|
| **Client** | React Native (Expo) — one team, iOS + Android. You're iOS-focused, but US couples are mixed-device; Android is ~50% of US. |
| **Local store** | SQLite / WatermelonDB — offline-first, sync queue |
| **Backend** | Supabase (Postgres + RLS + realtime + auth) or Firebase. Supabase if you want relational couple modeling. |
| **AI** | Claude API with a **couple-memory layer** (vector store of past entries, retrieved per-session) + safety classifier in front |
| **Payments** | RevenueCat → StoreKit / Play. Add Razorpay/UPI later for India. |
| **Push** | OneSignal or Expo Push, with per-user send-time optimization |
| **Analytics** | PostHog (self-hostable, content-agnostic) |
| **Encryption** | Client-side E2E for journal/chat. Server stores ciphertext. |

**Cost note:** AI inference is your main variable cost. Cache common responses, use a small model for classification and a large one for coaching.

---

# PART 7 — 90-DAY ROADMAP

### Days 1–30 · Foundation
- Lock v0.1 scope. Set up repo, backend, RevenueCat
- Build wisdom-track onboarding + Love Languages
- Build Solo Mode
- Start content engine: write 90 prompts (Secular + Biblical)
- Begin safety classifier

### Days 31–60 · The hard parts
- **Pairing suite** (all 6 screens) — do this early, it's your known failure mode
- Daily loop + journal + mood
- Relationship Pulse + weekly recap
- AI coach v1 with memory + voice
- Offline-first sync

### Days 61–90 · Launch prep
- Paywall, trial, pricing
- Safety + privacy pass
- TestFlight with **50 real couples** (recruit from interfaith/multi-cultural communities — your wedge)
- Fix what breaks. Instrument pairing funnel obsessively.
- App Store submission

---

# PART 8 — METRICS THAT MATTER

**The five numbers:**
1. **Pairing completion rate** — % of invites that become active pairs. Target **>60%**. This is your Anchored killer metric.
2. **D30 retention** — target **>25%** (couples apps run 10–20%)
3. **Weekly prompt completion** — target **>3/week per active partner**
4. **Trial → paid** — target **>25%** (US benchmark for 14-day trials)
5. **Solo → paired conversion** — % of solo users who eventually pair. This validates the whole Solo Mode bet.

---

# PART 9 — RISKS

| Risk | Severity | Mitigation |
|---|---|---|
| Partner never joins | 🔴 High | Solo Mode + pairing suite (both in v0.1) |
| AI says something harmful | 🔴 High | Safety classifier, scope disclaimers, human escalation |
| Content feels generic (Paired's flaw) | 🟠 Med | Deep personalization: per-partner wisdom + memory |
| Competitor copies multi-wisdom | 🟠 Med | Content depth + couple memory are hard to replicate fast |
| US liability around advice | 🟠 Med | Clear disclaimers, LLC formation, E&O insurance |
| AI inference costs scale badly | 🟡 Low | Caching, tiered models, usage caps |
| India expansion distracts | 🟡 Low | Build the hook now, don't activate until US is stable |

---

# PART 10 — ROUGH BUDGET (USD)

| Item | Solo / small team | With contractors |
|---|---|---|
| Design system (done) | $0 | $0 |
| Development (3 mo, you) | $0 | $25k–45k |
| Backend + infra (yr 1) | $1.5k | $1.5k |
| AI inference (yr 1, 10k users) | $3k–8k | $3k–8k |
| Content writing (90 prompts × 2 tracks) | $2k | $5k–10k |
| Legal (ToS, privacy, LLC) | $800 | $3k |
| App Store + misc | $500 | $500 |
| **Total** | **~$8k–13k** | **~$38k–70k** |

---

# THE BOTTOM LINE

**You have a genuinely differentiated idea with mature design work. The gaps are all execution gaps, and they're all solvable.**

**If you only do three things from this document:**
1. **Build Solo Mode + the 6-screen pairing suite.** This fixes the exact thing that broke Anchored, and nobody in the category has solved it.
2. **Make wisdom selection per-partner, not per-couple.** This is your US moat — interfaith couples are mainstream in America and completely unserved.
3. **Reprice to $79.99/yr, one subscription covers both.** You're currently under-priced and missing the industry-standard billing model.

Build v0.1 in 90 days. Get 50 couples. Then come back to the beautiful design system and scale it.
