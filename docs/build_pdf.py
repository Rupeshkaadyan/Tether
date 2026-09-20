#!/usr/bin/env python3
"""Build the Tether build log as a PDF: what was made, step by step."""

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (BaseDocTemplate, Frame, Image, KeepTogether,
                                PageBreak, PageTemplate, Paragraph, Spacer,
                                Table, TableStyle)

OUT = "/Users/rupesh/WorkBuddy AI/2026-09-17-18-08-02/TetherApp/docs/Tether_Build_Log.pdf"
SHOTS = "/tmp/shots"

INK = colors.HexColor("#1B1726")
MUTED = colors.HexColor("#6B6580")
BRAND = colors.HexColor("#5B4BC4")
LINE = colors.HexColor("#E3DFEC")
BAND = colors.HexColor("#F6F3FA")

ss = getSampleStyleSheet()


def S(name, **kw):
    base = dict(fontName="Helvetica", fontSize=10, leading=14,
                textColor=INK, alignment=TA_LEFT, spaceAfter=6)
    base.update(kw)
    return ParagraphStyle(name, **base)


title   = S("title", fontName="Helvetica-Bold", fontSize=26, leading=30, spaceAfter=4)
sub     = S("sub", fontSize=12, textColor=MUTED, leading=16, spaceAfter=2)
h1      = S("h1", fontName="Helvetica-Bold", fontSize=17, leading=21,
            spaceBefore=14, spaceAfter=7, textColor=BRAND)
h2      = S("h2", fontName="Helvetica-Bold", fontSize=11.5, leading=15,
            spaceBefore=9, spaceAfter=3)
body    = S("body", fontSize=9.6, leading=13.6, spaceAfter=5)
small   = S("small", fontSize=8.6, leading=12, textColor=MUTED, spaceAfter=3)
bullet  = S("bullet", fontSize=9.6, leading=13.4, leftIndent=11,
            bulletIndent=2, spaceAfter=2.5)
code    = S("code", fontName="Courier", fontSize=8.2, leading=11,
            textColor=colors.HexColor("#8E3A61"), leftIndent=8, spaceAfter=5)
cap     = S("cap", fontSize=7.8, leading=10.5, textColor=MUTED, spaceAfter=8)

story = []


def para(t, st=body):
    story.append(Paragraph(t, st))


def bullets(items, st=bullet):
    for it in items:
        story.append(Paragraph(it, st, bulletText="•"))
    story.append(Spacer(1, 4))


def gap(h=6):
    story.append(Spacer(1, h))


def shot(name, caption, height=88 * mm):
    """Phone screenshot centred, with a caption underneath."""
    p = f"{SHOTS}/sm_{name}.png"
    try:
        img = Image(p)
    except Exception:
        return
    r = img.imageHeight / img.imageWidth
    img.drawWidth = height / r
    img.drawHeight = height
    img.hAlign = "CENTER"
    story.append(Spacer(1, 3))
    story.append(img)
    story.append(Paragraph(caption, cap))
    story.append(Spacer(1, 2))


def stat_table(rows):
    t = Table(rows, colWidths=[62 * mm, 62 * mm, 46 * mm])
    t.setStyle(TableStyle([
        ("FONT", (0, 0), (-1, 0), "Helvetica-Bold", 8.6),
        ("FONT", (0, 1), (-1, -1), "Helvetica", 8.6),
        ("TEXTCOLOR", (0, 0), (-1, 0), MUTED),
        ("TEXTCOLOR", (0, 1), (-1, -1), INK),
        ("BACKGROUND", (0, 0), (-1, 0), BAND),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, BAND]),
        ("GRID", (0, 0), (-1, -1), 0.4, LINE),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    story.append(t)
    story.append(Spacer(1, 6))


# ----------------------------------------------------------------- cover
story.append(Spacer(1, 26 * mm))
para("Tether", title)
para("A quiet daily ritual you share with one person.", sub)
para("Complete build log &mdash; everything made, and why.", sub)
gap(14)

para("What this is", h1)
para(
    "Tether is a native iOS app for couples, built local-first and offline. "
    "Everything is stored on device and encrypted; there is no server holding "
    "anyone's writing. This document records what was built, the decisions "
    "behind it, the bugs found along the way, and the reasoning that is easy "
    "to lose once the code is written."
)
gap(4)

para("At a glance", h1)
stat_table([
    ["Measure", "Value", "Note"],
    ["Swift source files", "58", "plus a widget target"],
    ["Lines of Swift", "17,123", "hand-written"],
    ["Commits", "121", "one per logical change"],
    ["Localised strings", "563", "English, Hindi, Spanish"],
    ["Scenes (themes)", "11", "2 free + glass, rest paid"],
    ["Wisdom paths", "4", "Secular, Vedic, Quranic, Biblical"],
    ["Daily prompts", "360", "90 per path"],
])

story.append(PageBreak())

# ------------------------------------------------------------- 1. screens
para("1. The app, screen by screen", h1)

para("Home &mdash; the sky, the tether, the ritual", h2)
para(
    "Home opens on a drawn sky that belongs to the chosen scene, with the day's "
    "ritual directly beneath it: a mood, a line of writing, and an explicit "
    "choice about who it is for. Below that sit the warmth chips, the pulse, "
    "and a two-column gallery rather than a list of buttons."
)
bullets([
    "<b>The masthead</b> is scene art, not a photo. Fireflies at Night, "
    "butterflies in the Garden, a seed on the wind in the Meadow.",
    "<b>The tether</b> is drawn as a real slack curve between two people, "
    "with their photos. Unpaired, it hangs loose and dashed &mdash; visibly "
    "waiting rather than broken.",
    "<b>The gallery</b> replaced ten stacked buttons. Each tile carries a live "
    "badge and a detail line that changes with state.",
])
shot("01_home_glass", "Home in the Glass theme &mdash; translucent cards over a pale sky, "
                      "with the journal preview strip showing real thumbnails.")
shot("02_home_jungle", "Home in Jungle &mdash; canopy silhouette, green throughout, "
                       "tinted cards. The whole screen is one place.")

para("Journal &mdash; yours, and shared", h2)
para(
    "Two tabs that never overlap: <b>Only me</b> and <b>Shared</b>. Each entry "
    "shows its date, its time, and in words whether anyone else can see it. "
    "Long-press or swipe from either edge to move an entry between them, or "
    "delete it."
)
bullets([
    "<b>Private by default.</b> Sharing is a deliberate act, not the absence "
    "of one.",
    "<b>Writable from the journal.</b> A compose button, which did not exist "
    "before this session.",
    "<b>Voice, photo or text</b>, all shown as themselves in the preview strip.",
])
shot("03_journal", "The journal in Jungle &mdash; entries grouped by month, each labelled "
                   "Only me or Shared in words.")

story.append(PageBreak())

para("Grow &mdash; the seven day practice", h2)
para(
    "A seven day sequence that builds the habit. Each day closes with a "
    "reflection, and completing the week is marked rather than merely counted."
)
shot("04_grow", "Grow &mdash; the seven day practice, with progress and today's step.")

story.append(PageBreak())

para("Insights &mdash; the shape of a stretch of time", h2)
para(
    "Mood over time, distribution, streaks, and a love-language reflection. "
    "All computed on device from entries that are already there; nothing is "
    "sent anywhere to produce it."
)
shot("05_pulse", "Insights &mdash; the pulse, trends and the sentence that says "
                 "what they actually mean.")

story.append(PageBreak())

# ------------------------------------------------------------- 2. features
para("2. What was built in this session", h1)
para(
    "Everything below was made in a single working session, in response to "
    "reported bugs and to choices you made about direction."
)

para("The Two Versions &mdash; the feature you picked", h2)
para(
    "Both people write their own memory of the same day. Neither sees the "
    "other's until both have written. Then both are shown, side by side, with "
    "no verdict."
)
para(
    "It only surfaces on days where both wrote <i>and</i> at least one found it "
    "hard. The single line of commentary is: <i>&ldquo;You were both having a "
    "hard day, and neither of you knew the other was too. Neither of you is "
    "wrong.&rdquo;</i> It never says who was right. It is a window, not a "
    "verdict."
)

para("Quiet Week", h2)
para(
    "One tap: <i>&ldquo;I need a quiet week.&rdquo;</i> Three, seven or fourteen "
    "days, with an optional line the partner sees. Notifications stop for "
    "<b>both</b> people. No streak breaks, nothing to catch up on."
)
para(
    "The partner's screen says the thing that matters: <i>&ldquo;This is not "
    "about you. They asked for space, and told you so &mdash; which is the "
    "opposite of disappearing.&rdquo;</i>"
)
para(
    "Every other couples app is built to maximise engagement, which is exactly "
    "why none of them has this. A pause button works against the business "
    "model. This turns a withdrawal into a message."
)

para("Eleven scenes, each with its own horizon", h2)
para(
    "Match phone &middot; Glass &middot; Day &middot; Dawn &middot; Night "
    "&middot; Garden &middot; Jungle &middot; Ocean &middot; Dune &middot; "
    "Aurora &middot; Meadow."
)
para(
    "A scene owns the whole header: its sky, its light, its colours, and its "
    "<b>silhouette</b>. That last part matters most &mdash; recolouring the same "
    "two hills green still reads as hills. So Jungle and Garden get layered "
    "foliage, Ocean a flat banded waterline, Dune soft shoulders, Meadow low "
    "rolling grass, and the sky scenes keep the ridges."
)
para(
    "Stars now follow the scene rather than the clock. A dark Jungle sky used to "
    "sprout stars at 2am that were not there."
)

para("Privacy &mdash; the core promise", h2)
bullets([
    "Every entry is <b>encrypted on device</b> before it is stored, with the "
    "key in the Secure Enclave.",
    "<b>Private by default.</b> This was a real bug: entries defaulted to "
    "shared, so the Only me tab was always empty and keeping something to "
    "yourself was impossible.",
    "<b>Face ID</b> on cold launch and on return from background.",
    "<b>Unsent notes</b> &mdash; a place to think before speaking. The partner "
    "never learns how many exist.",
    "Crisis content is detected on device, handled with care, and never "
    "distilled into retrievable memory.",
])

story.append(PageBreak())

# ------------------------------------------------------------- 3. bugs
para("3. Bugs found and fixed", h1)
para(
    "Most of these came from you using the app on a real phone, which is the "
    "only way they were ever going to surface."
)

para("The journal could not be written privately", h2)
para("Found because the Only me tab was always empty.", small)
para(
    "<font face='Courier' size='8.5'>self.visibilityRaw = Visibility.shared."
    "rawValue</font>"
)
para(
    "Every entry defaulted to shared, and nothing ever changed it. There was no "
    "control to change it with. Keeping something private meant not writing it "
    "at all. Fixed to private by default, with an explicit picker."
)

para("Face ID only worked from the app switcher", h2)
para("Found because quitting and reopening opened straight into the journal.", small)
para(
    "<font face='Courier' size='8.5'>isLocked</font> starts "
    "<font face='Courier' size='8.5'>false</font>, and "
    "<font face='Courier' size='8.5'>lock()</font> was only called from "
    "<font face='Courier' size='8.5'>scenePhase == .background</font>. A cold "
    "start asked for nothing. Now locked in "
    "<font face='Courier' size='8.5'>init()</font> as well."
)

para("Writing in Shared did nothing", h2)
para("Two causes, both real.", small)
bullets([
    "The visibility picker was <b>hidden entirely</b> unless a partner existed, "
    "so an unpaired person wrote into Shared and the entry silently saved as "
    "private.",
    "Even when it saved correctly, the journal stayed on the tab you were "
    "already on, so the screen looked unchanged.",
])

para("The phone getting hot", h2)
para(
    "The animated backdrop ran at the display's native rate &mdash; 120 times a "
    "second on ProMotion &mdash; on every screen, forever, redrawing a canvas "
    "full of radial gradients. Nothing there moves fast enough for anyone to "
    "tell the difference, so the rate is now matched to the content:"
)
stat_table([
    ["Surface", "Was", "Now"],
    ["Ambient backdrop", "120 fps", "8 fps"],
    ["Header", "120 fps", "8 fps"],
    ["Jar", "120 fps", "16 fps"],
    ["Drawn note", "120 fps", "20 fps"],
])

para("&ldquo;Invalid frame dimension&rdquo;", h2)
para(
    "This is layout maths producing a NaN or a negative, not a performance "
    "problem &mdash; so raising the frame rate would only have logged it more "
    "often. Three separate sources were found:"
)
bullets([
    "<b>A NaN clamp that does not clamp.</b> "
    "<font face='Courier' size='8.5'>min(max(Double(rms) * 14, 0), 1)</font> "
    "returns NaN, because every comparison against NaN is false in Swift. One "
    "bad audio sample became a NaN frame width.",
    "<b>Unguarded geometry.</b> A "
    "<font face='Courier' size='8.5'>GeometryReader</font> inside a scrolling "
    "List can be handed a negative size while rows are recycled. Every "
    "reader feeding a frame or a shape is now clamped.",
    "<b>A division inside a frame.</b> "
    "<font face='Courier' size='8.5'>count / maxCount</font> with a zero "
    "denominator. Now guarded.",
])

para("A Spacer was being made into a bar button", h2)
para(
    "<font face='Courier' size='8.5'>ToolbarItemGroup</font> makes every child "
    "its own bar item, so a <font face='Courier' size='8.5'>Spacer()</font> "
    "became a zero-width button that UIKit could not satisfy next to the real "
    "one. Five keyboard toolbars were affected. They now use a single "
    "<font face='Courier' size='8.5'>ToolbarItem</font>."
)

para("Home grew without bound", h2)
para(
    "Home rendered up to ten full journal cards inline, so the screen got "
    "longer every time you wrote &mdash; and each card blends a material over "
    "the backdrop, which is the most expensive thing on the screen. Replaced "
    "with one row that opens the journal, plus a thumbnail strip."
)

story.append(PageBreak())

# ------------------------------------------------------------- 4. platform
para("4. Platform work", h1)
para(
    "Audited against the iOS essentials rather than guessing. Present: widget, "
    "Reduced Motion, ShareLink, Face ID, haptics, context menus, VoiceOver, "
    "Dynamic&nbsp;Type, dark mode, three languages, empty states, StoreKit."
)
para("Added this session:", h2)
bullets([
    "<b>Swipe actions</b> on journal rows, from both edges.",
    "<b>Home Screen quick actions</b> &mdash; long-press the icon for New "
    "entry, Today's question, or Quiet week.",
    "<b>Photo cropping</b> with pinch, drag and reset.",
    "<b>Profile photos</b>, downsampled before storage.",
    "<b>Three accents</b> &mdash; Classic indigo, Bold steel blue, Warm rose "
    "&mdash; with gender choosing the starting one.",
])

para("A note on the widget", h2)
para(
    "The widget exists as its own target, "
    "<font face='Courier' size='8.5'>TetherWidget/</font>. Adding more widget "
    "families &mdash; a graph, a streak &mdash; means writing a timeline "
    "provider for each, and paywalling them means sharing entitlement state "
    "across targets through an App&nbsp;Group. Both are real work and both "
    "remain open."
)

para("Localisation", h2)
para(
    "563 strings across English, Hindi and Spanish. A checker script "
    "(<font face='Courier' size='8.5'>check_localization.py</font>) runs "
    "against the build output. Three blind spots were found in it this session, "
    "each of which had hidden real gaps:"
)
bullets([
    "It cannot see strings inside <b>ternary branches</b>.",
    "It cannot see strings from <b>computed LocalizedStringKey properties</b>.",
    "It cannot see strings built with <b>interpolation</b>.",
])
para(
    "A clean scan is not proof of a complete translation. Roughly forty strings "
    "were added by hand after the checker reported nothing wrong.",
    small,
)

story.append(PageBreak())

# ------------------------------------------------------------- 5. next
para("5. What is still open", h1)
para("Stated honestly, so nothing here reads as finished when it is not.")

stat_table([
    ["Item", "State", "What it needs"],
    ["Insights in widgets", "Not started", "Widget target + App Group"],
    ["More widget families", "Not started", "A timeline provider each"],
    ["Paywalled widgets", "Not started", "Entitlement sharing"],
    ["Grow after day 7", "Open", "A design decision from you"],
    ["Ritual 'everyday'", "Open", "Clarity on what it should mean"],
    ["Pulse enrichment", "Blocked", "A screenshot of what looks empty"],
    ["Live Activity", "Not started", "ActivityKit"],
    ["Spotlight &amp; Siri", "Not started", "App Intents"],
])

gap(8)
para("How to verify any of this on a device", h1)
bullets([
    "Long-press the Tether icon &mdash; three shortcuts should appear and work.",
    "Swipe a journal entry from either edge &mdash; Delete and Share.",
    "Write in Shared, then check it lands in Shared and not Only me.",
    "Force-quit and reopen &mdash; Face ID should ask.",
    "Scroll Settings and the journal &mdash; the console should stay clean.",
])

gap(10)
para(
    "Built with SwiftUI and SwiftData. Local-first, offline, encrypted, no "
    "account. 58 source files, 17,123 lines, 121 commits.",
    small,
)


# ------------------------------------------------------------- render
def decorate(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 7.5)
    canvas.setFillColor(MUTED)
    canvas.drawString(20 * mm, 12 * mm, "Tether — build log")
    canvas.drawRightString(A4[0] - 20 * mm, 12 * mm, "Page %d" % doc.page)
    canvas.setStrokeColor(LINE)
    canvas.setLineWidth(0.4)
    canvas.line(20 * mm, 15 * mm, A4[0] - 20 * mm, 15 * mm)
    canvas.restoreState()


doc = BaseDocTemplate(OUT, pagesize=A4,
                      leftMargin=20 * mm, rightMargin=20 * mm,
                      topMargin=18 * mm, bottomMargin=20 * mm,
                      title="Tether — Build Log",
                      author="Tether")
frame = Frame(doc.leftMargin, doc.bottomMargin,
              doc.width, doc.height, id="body")
doc.addPageTemplates([PageTemplate(id="main", frames=[frame],
                                   onPage=decorate)])
doc.build(story)
print("written:", OUT)
