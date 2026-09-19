#!/usr/bin/env python3
"""Check Tether's string catalog for gaps.

Run this after adding any UI. It catches two distinct problems, and the second
is the one that keeps slipping through:

1. Strings in the catalog with an EMPTY `localizations` dict — no English, no
   Hindi, no Spanish. Counting "how many lack Hindi" looks healthy and hides
   these completely.

2. UI string literals in the Swift sources that are NOT in the catalog at all.
   xcodebuild does NOT auto-extract strings — only Xcode's IDE does. So a new
   Text("...") is invisible to translation until someone adds it by hand, and
   the app silently shows English in every language.

Usage:  python3 check_localization.py
Exit code 1 if anything needs attention, so it can gate a commit.
"""

import glob
import json
import os
import re
import sys

CATALOG = "Tether/Localizable.xcstrings"
SOURCES = "Tether/*.swift"

# Call sites that SwiftUI renders as text. Deliberately narrow — a loose match
# would flag log messages, keys and identifiers as "untranslated UI".
PATTERNS = [
    r'Text\(\s*"((?:[^"\\]|\\.)*)"',
    r'Button\(\s*"((?:[^"\\]|\\.)*)"',
    r'Label\(\s*"((?:[^"\\]|\\.)*)"',
    r'\.navigationTitle\(\s*"((?:[^"\\]|\\.)*)"',
    r'SectionHeader\(title:\s*"((?:[^"\\]|\\.)*)"',
    r'TextField\(\s*"((?:[^"\\]|\\.)*)"',
    r'SharePreview\(\s*"((?:[^"\\]|\\.)*)"',
]

# The catalog KEY is the English string, so `en` is implicit and most entries
# carry no explicit English unit. Requiring it flags 281 strings that are
# perfectly fine. These two are the real requirements.
REQUIRED_LANGUAGES = ("hi", "es")


def main() -> int:
    if not os.path.exists(CATALOG):
        print(f"ERROR: {CATALOG} not found. Run from TetherApp/.")
        return 1

    catalog = json.load(open(CATALOG, encoding="utf-8"))["strings"]

    # 1. Entries with nothing at all.
    empty = sorted(k for k, v in catalog.items() if not v.get("localizations"))

    # 1b. Entries missing a required language.
    incomplete = sorted(
        k for k, v in catalog.items()
        if v.get("localizations")
        and not set(REQUIRED_LANGUAGES) <= set(v["localizations"])
    )

    # 2. UI literals that never made it into the catalog.
    literals = set()
    for path in glob.glob(SOURCES):
        src = open(path, encoding="utf-8").read()
        for pattern in PATTERNS:
            for m in re.finditer(pattern, src):
                text = m.group(1)
                # Skip interpolated strings: those become %@/%lld keys and are
                # checked separately, not as literals.
                if text and "\\(" not in text:
                    literals.add(text)
    missing = sorted(literals - set(catalog))

    print(f"catalog entries:     {len(catalog)}")
    print(f"UI literals found:   {len(literals)}")
    print()
    print(f"empty localizations: {len(empty)}")
    print(f"missing a language:  {len(incomplete)}")
    print(f"not in catalog:      {len(missing)}")

    def dump(title, items):
        if items:
            print(f"\n{title}")
            for s in items:
                print("  -", repr(s[:88]))

    dump("Empty — no en/hi/es at all:", empty)
    dump("Missing a required language:", incomplete)
    dump("UI literals absent from the catalog:", missing)

    problems = len(empty) + len(incomplete) + len(missing)
    if problems:
        print(f"\n{problems} issue(s). Localization is incomplete.")
        return 1

    print("\nAll clear.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
