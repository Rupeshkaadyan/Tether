#!/usr/bin/env python3
"""Render tab-bar-sized variants of four icons.

`tabItem` re-renders its icon itself and ignores `.resizable()` / `.frame()`, so
the only thing that controls tab icon size is the asset's intrinsic size. An
imageset with a single 3x entry gets an intrinsic size of pixels / 3 — so 78px
gives a 26pt tab icon, which is the iOS standard.
"""
import pathlib, subprocess, re, json

SRC = pathlib.Path("/Users/rupesh/Downloads/Tether_Complete_Assets/SVG_Icons")
ROOT = pathlib.Path(__file__).parent
ASSETS = ROOT / "Tether/Assets.xcassets/Icons"
TMP = ROOT / "Branding/.tmp"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

PX = 78            # 26pt at 3x
TABS = {
    "tab_home":    SRC / "navigation/home.svg",
    "tab_journal": SRC / "navigation/journal.svg",
    "tab_coach":   SRC / "navigation/coach.svg",
    "tab_pulse":   SRC / "insights/pulse.svg",
}

TMP.mkdir(parents=True, exist_ok=True)
for name, svg in TABS.items():
    if not svg.exists():
        print(f"{name}: MISSING {svg}")
        continue

    body = re.sub(r'(stroke|fill)="#[0-9A-Fa-f]{3,6}"',
                  lambda m: f'{m.group(1)}="currentColor"', svg.read_text())
    html = ('<!DOCTYPE html><html><head><meta charset="utf-8"><style>'
            'html,body{margin:0;padding:0;width:%dpx;height:%dpx;background:transparent;'
            'color:#000}svg{width:%dpx;height:%dpx;display:block}</style></head><body>%s'
            '</body></html>' % (PX, PX, PX, PX, body))
    hp = TMP / "render.html"
    hp.write_text(html)

    stage = TMP / f"{name}.png"
    if stage.exists():
        stage.unlink()

    subprocess.run(["pkill", "-f", "Google Chrome.*headless"], capture_output=True)
    try:
        subprocess.run([CHROME, "--headless", "--disable-gpu", "--no-sandbox",
                        "--hide-scrollbars", "--default-background-color=00000000",
                        f"--window-size={PX},{PX}", f"--screenshot={stage}",
                        f"file://{hp.resolve()}"],
                       capture_output=True, timeout=25)
    except subprocess.TimeoutExpired:
        print(f"{name}: TIMEOUT")
        continue

    if not (stage.exists() and stage.stat().st_size > 100):
        print(f"{name}: render failed")
        continue

    iset = ASSETS / f"{name}.imageset"
    iset.mkdir(parents=True, exist_ok=True)
    (iset / f"{name}.png").write_bytes(stage.read_bytes())
    (iset / "Contents.json").write_text(json.dumps({
        "images": [{"idiom": "universal", "scale": "3x", "filename": f"{name}.png"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {"template-rendering-intent": "template"}}, indent=2) + "\n")
    print(f"{name}: ok ({PX}px @3x = 26pt)")
