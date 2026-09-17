# ChatGPT Build Prompt — Tether

Paste everything below the line into ChatGPT. It contains the exact SVG source
for the brand, so ChatGPT does not need to generate any images.

---

You are a senior product designer and front-end engineer. Build a complete,
high-fidelity, interactive prototype of an app called **Tether**.

**Critical:** you cannot generate images. Do not try. Everything visual below is
given to you as **exact SVG code and exact hex values**. Use them verbatim. Do not
invent your own icons, colours, or logo — the brand is already defined.

---

## 1. What Tether is

A private app for two people in a relationship. Each partner answers **one short
question a day** — one sentence is enough — and neither sees the other's answer
until both have replied. It is a small daily ritual, not a curriculum and not
therapy.

Its defining idea: **each partner chooses their own wisdom track** — Secular &
Psychology, Biblical, Vedic & Dharmic, or Quranic. A Hindu and a Christian partner
each get content in their own framework while sharing the same daily practice.
Every other couples app assumes a shared worldview. Tether is built for when
there isn't one.

**Tone:** warm, calm, plain-spoken. Never clinical, never preachy, never cheerful
about something serious.

---

## 2. The brand mark — use this EXACT SVG, verbatim

A single curve joining two points, with slack between them. Two people,
connected, still free to move.

```svg
<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <path d="M 300 336 C 566 336, 458 688, 724 688"
        fill="none" stroke="#5B4BC4" stroke-width="46" stroke-linecap="round"/>
  <circle cx="300" cy="336" r="74" fill="#5B4BC4"/>
  <circle cx="724" cy="688" r="74" fill="#5B4BC4"/>
</svg>
```

To recolour it, change `#5B4BC4` on all three elements. To place it on a dark
background use `#FFFFFF`. Never stretch it — keep it square.

**App icon** — same mark, inverted, on the brand field:

```svg
<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <rect width="1024" height="1024" fill="#3C3489"/>
  <path d="M 300 336 C 566 336, 458 688, 724 688"
        fill="none" stroke="#AFA9EC" stroke-width="46" stroke-linecap="round"/>
  <circle cx="300" cy="336" r="74" fill="#EEEDFE"/>
  <circle cx="724" cy="688" r="74" fill="#EEEDFE"/>
  <circle cx="300" cy="336" r="30" fill="#3C3489"/>
  <circle cx="724" cy="688" r="30" fill="#3C3489"/>
</svg>
```

---

## 3. Wallpapers — output these as SVG too

Three phone wallpapers, 1290 × 2796. Same mark, scaled up and very soft.

```svg
<!-- DUSK -->
<svg viewBox="0 0 1290 2796" xmlns="http://www.w3.org/2000/svg">
  <defs><linearGradient id="d" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0%" stop-color="#2E2456"/><stop offset="100%" stop-color="#5B4BC4"/>
  </linearGradient></defs>
  <rect width="1290" height="2796" fill="url(#d)"/>
  <g opacity="0.55">
    <path d="M 300 940 C 1130 1000, 160 1800, 990 1890" fill="none"
          stroke="#8E7FE8" stroke-width="30" stroke-linecap="round"/>
    <circle cx="300" cy="940" r="62" fill="#FFFFFF" opacity="0.95"/>
    <circle cx="990" cy="1890" r="62" fill="#FFFFFF" opacity="0.95"/>
  </g>
</svg>

<!-- DAWN -->
<svg viewBox="0 0 1290 2796" xmlns="http://www.w3.org/2000/svg">
  <defs><linearGradient id="w" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0%" stop-color="#FDF6EF"/><stop offset="100%" stop-color="#F7DCE4"/>
  </linearGradient></defs>
  <rect width="1290" height="2796" fill="url(#w)"/>
  <g opacity="0.85">
    <path d="M 300 940 C 1130 1000, 160 1800, 990 1890" fill="none"
          stroke="#E3A87C" stroke-width="30" stroke-linecap="round"/>
    <circle cx="300" cy="940" r="62" fill="#FFFFFF" opacity="0.95"/>
    <circle cx="990" cy="1890" r="62" fill="#FFFFFF" opacity="0.95"/>
  </g>
</svg>

<!-- NIGHT -->
<svg viewBox="0 0 1290 2796" xmlns="http://www.w3.org/2000/svg">
  <defs><linearGradient id="n" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0%" stop-color="#141024"/><stop offset="100%" stop-color="#2A2050"/>
  </linearGradient></defs>
  <rect width="1290" height="2796" fill="url(#n)"/>
  <g opacity="0.75">
    <path d="M 300 940 C 1130 1000, 160 1800, 990 1890" fill="none"
          stroke="#6A57D6" stroke-width="26" stroke-linecap="round"/>
    <circle cx="300" cy="940" r="62" fill="#B9AEF5" opacity="0.95"/>
    <circle cx="990" cy="1890" r="62" fill="#B9AEF5" opacity="0.95"/>
  </g>
</svg>
```

---

## 4. Design system — use these exact values

**The feeling:** warm paper, not clinical white. Calm, unhurried, generous space.
Something you would not mind a partner seeing over your shoulder.

### Colour

| Role | Hex | Use |
|---|---|---|
| Background | `#FDFBF8` | Every screen. Warm cream — **never pure white**. |
| Surface | `#FFFFFF` | Cards floating on the cream |
| Sunken surface | `#F6F2EC` | Inputs, secondary panels |
| Border | `#EAE4DA` | Hairlines |
| Text | `#2A2438` | Warm near-black. **Never `#000`.** |
| Text muted | `#6F6879` | Secondary text |
| Brand | `#5B4BC4` | Primary actions |
| Brand soft | `#EEEAFB` | Tinted fills |
| Warm accent | `#E08A4B` | Terracotta — the emotional counterweight |
| Rose | `#D96A8A` | Celebration, accents |
| Thriving | `#2E9E6B` | Positive state |
| Drifting | `#D08A28` | Caution state |
| Strained | `#C4463F` | Needs attention |

**Brand gradient** (buttons, the daily prompt card):
`linear-gradient(135deg, #6A57D6 0%, #4A3AA8 100%)`

**Track identity colours** — so you can tell whose content you are reading:
Secular `#4A7DBF` · Biblical `#7B6BD6` · Vedic `#D98A2B` · Quranic `#2E9E7B`

### Type

System font stack, **rounded feel** — use `font-family: ui-rounded, -apple-system, system-ui, sans-serif`.

| Style | Size / line-height | Weight |
|---|---|---|
| Display | 34 / 40 | 700 |
| Screen title | 28 / 34 | 700 |
| Daily prompt | 21 / 30 | 600 |
| Headline | 19 / 26 | 600 |
| Body | 16.5 / 26 | 400 |
| Label | 15.5 / 20 | 600 |
| Caption | 13 / 18 | 400 |

### Shape, depth, motion

- Card radius **24px**. Button radius **16px**. Sheet radius **32px**.
- Cards: white, 1px `#EAE4DA` border, shadow `0 3px 10px rgba(42,36,56,0.05)`.
- Buttons: **54px tall**, brand gradient, shadow `0 8px 18px rgba(42,36,56,0.08)`,
  and a gentle scale to 0.975 on press with a spring.
- Screen padding: **22px** horizontal.
- Motion is **slow and calm**. 250ms cross-fades. A 4.5-second breathing gradient
  behind the daily prompt so there is a moment to breathe before answering.
  Nothing bounces. Nothing celebrates loudly.

---

## 5. Build these screens

Design each at **390 × 844** (iPhone). Show them side by side on a soft
`#F1EDE6` backdrop.

**1. Welcome**
A 400px-tall panel with the dusk gradient, rounded 44px at the bottom only. The
mark centred at 148px, white. Below it "Tether" in 42px bold white, then "Two
people. One practice." in 15px white at 82% opacity. Below the panel, on cream: a
line of body copy, then a labelled input for the user's name, then a full-width
gradient button reading "Get started".

**2. Choose your wisdom track**
Title: "What wisdom speaks to you?" Subhead, and this line is important:
*"This is yours alone. Your partner chooses their own."*
Four cards, equal weight, no ranking. Each has a 46px coloured circle containing
a simple glyph, the track name, and one line of description. Selected state:
2px coloured border, filled circle, checkmark on the right.

**3. Home — the daily loop**
Top: a small muted line "Good evening · 17 Sep", then the user's name at 28px.
Right: a circular streak ring showing "4", and a floating circular settings button.
Below: a connection card with **two circular avatars** — the partner's drawn as a
dashed empty circle until they join. Then a Pulse card (small, white, showing
"Thriving · Improving"). Then the hero: a **gradient card** with the day's
question in 21px white, a small translucent chip reading the track name, and the
date in the top right. Then a row of five mood dots, then a one-line input with a
microphone icon, then a gradient "Save today's entry" button.

**4. Waiting room**
A status line with an amber dot: "Waiting for your partner · Sent 2h ago".
A large QR code in a white rounded square. Below it a card with a 6-digit code in
28px monospace with a copy button. Then a card headed "Not sure what to say? Send
this:" containing a short pre-written message and a copy button. Then a soft
secondary button "Send a reminder", and a plain text link "Continue on my own".

**5. The coach**
A chat thread. The user's messages right-aligned in brand gradient with white
text; the coach's left-aligned on white with a warm border. Above one coach
message, a tiny label with a clock icon reading **"Remembering"** in brand colour.
At the bottom an input bar with a microphone and a circular send button. Under it,
in 11px muted: "Tether is not therapy and not a crisis service."

**6. Crisis support card**
Calm, high contrast, **unbranded** — no logo, no gradient. A heading:
"It sounds like you are carrying something very heavy." Body text. Then three
white rows, each with a helpline name, a one-line description, and a phone number
in brand colour at 17px semibold. At the bottom, small and muted:
**"Your partner is not told about this."**

**7. Paywall**
Title "Keep the practice going". Immediately below it, a tinted banner with two
small avatar circles and the line, in semibold:
**"One subscription. Both partners. Always."**
Then five feature rows, each a small coloured glyph plus a title and one line.
Then three selectable price cards, the yearly one pre-selected with a "Best value"
badge. Then a full-width gradient button "Start 3-day free trial", a line of small
print, and a "Restore purchases" text link.

---

## 6. Deliverable

A **single self-contained HTML file** with inline CSS. No external images, no
icon libraries, no frameworks — draw everything with SVG and CSS. Use system
fonts only.

Make it genuinely interactive: the mood dots selectable, the track cards
selectable, the price cards selectable. Use subtle transitions.

Add a toggle at the top that switches the preview between **light mode** and a
**dark mode** where the background becomes `#141024` and cards become `#1F1830`
with the same accent colours.

---

## 7. Rules

1. **Never generate or reference an image file.** Everything is SVG or CSS.
2. **Never substitute an icon library.** Draw simple glyphs yourself as SVG paths.
3. **Use the exact hex values.** Do not "improve" the palette.
4. **Never pure white or pure black.** Warm cream and warm near-black only.
5. **No emoji anywhere.**
6. **Nothing bounces or confetti-fires.** This app is opened at quiet, sometimes
   vulnerable moments.
7. **No religious imagery of any kind.** No crosses, no om symbols, no crescent.
   The four tracks are represented by colour and simple abstract glyphs only.

Start by showing me the Welcome and Home screens, then continue through the rest.
