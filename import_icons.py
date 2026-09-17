#!/usr/bin/env python3
"""Render the Tether SVG icon pack into the Xcode asset catalog as template images.

Non-destructive and RESUMABLE: skips icons that already exist, never deletes.

Headless Chrome accumulates zombie processes and starts hanging after roughly
20-30 launches, so we kill stale headless instances before every render and keep
the per-render timeout short. Run this script repeatedly until it reports 0 left.
"""
import pathlib, subprocess, re, json, sys

SRC = pathlib.Path("/Users/rupesh/Downloads/Tether_Complete_Assets/SVG_Icons")
ROOT = pathlib.Path(__file__).parent
ASSETS = ROOT / "Tether/Assets.xcassets/Icons"
TMP = ROOT / "Branding/.tmp"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SIZE = 256
TIMEOUT = 20

TMP.mkdir(parents=True, exist_ok=True)
ASSETS.mkdir(parents=True, exist_ok=True)
(ASSETS / "Contents.json").write_text(
    json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n")

svgs = sorted(p for p in SRC.rglob("*.svg") if "tether-mark" not in p.name)
if not svgs:
    sys.exit("no svgs found")

def asset_name(p):
    return f"{p.parent.name.replace('-', '_')}_{p.stem.replace('-', '_')}"

def done(name):
    png = ASSETS / f"{name}.imageset" / f"{name}.png"
    return png.exists() and png.stat().st_size > 200

todo = [s for s in svgs if not done(asset_name(s))]
print(f"total={len(svgs)} already_done={len(svgs) - len(todo)} todo={len(todo)}", flush=True)
if not todo:
    print("ALL DONE", flush=True)
    sys.exit(0)

made, failed = 0, []
for svg in todo:
    name = asset_name(svg)
    body = re.sub(r'(stroke|fill)="#[0-9A-Fa-f]{3,6}"',
                  lambda m: f'{m.group(1)}="currentColor"', svg.read_text())
    html = ('<!DOCTYPE html><html><head><meta charset="utf-8"><style>'
            'html,body{margin:0;padding:0;width:%dpx;height:%dpx;background:transparent;'
            'color:#000}svg{width:%dpx;height:%dpx;display:block}</style></head><body>%s'
            '</body></html>' % (SIZE, SIZE, SIZE, SIZE, body))
    hp = TMP / "render.html"
    hp.write_text(html)

    stage = TMP / f"{name}.png"
    if stage.exists():
        stage.unlink()

    # clear zombies so the next launch isn't blocked by a wedged profile
    subprocess.run(["pkill", "-f", "Google Chrome.*headless"],
                   capture_output=True)
    try:
        subprocess.run([CHROME, "--headless", "--disable-gpu", "--no-sandbox",
                        "--hide-scrollbars", "--default-background-color=00000000",
                        f"--window-size={SIZE},{SIZE}", f"--screenshot={stage}",
                        f"file://{hp.resolve()}"],
                       capture_output=True, timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        failed.append(name)
        continue

    if not (stage.exists() and stage.stat().st_size > 200):
        failed.append(name)
        continue

    iset = ASSETS / f"{name}.imageset"
    iset.mkdir(parents=True, exist_ok=True)
    (iset / f"{name}.png").write_bytes(stage.read_bytes())
    (iset / "Contents.json").write_text(json.dumps({
        "images": [{"filename": f"{name}.png", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {"template-rendering-intent": "template"}}, indent=2) + "\n")
    made += 1

remaining = sum(1 for s in svgs if not done(asset_name(s)))
print(f"RESULT made={made} failed={len(failed)} remaining={remaining}", flush=True)
if failed:
    print("failed:", failed, flush=True)
