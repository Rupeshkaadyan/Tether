#!/usr/bin/env python3
"""Compile Safety.swift with a test harness and check the classifier.

Safety logic is the one place in this codebase where a silent regression harms
a person, so it gets an executable check rather than a read-through.
"""
import pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).parent
SRC = ROOT / "Tether/Safety.swift"
OUT = ROOT / "Branding/.tmp/safety_test.swift"

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(SRC.read_text() + '''

// ---- test harness ----
let mustFlag: [(String, SafetyCategory)] = [
    ("I want to die", .selfHarm),
    ("I don't want to be here anymore", .selfHarm),
    ("honestly I've been thinking about ending my life", .selfHarm),
    ("I have been cutting myself again", .selfHarm),
    ("my husband hit me last night", .abuse),
    ("he has been hitting me for months", .abuse),
    ("he grabbed me by the throat", .abuse),
    ("I am scared of my partner", .abuse),
    ("he threatened to kill me", .abuse),
    ("he controls my money and I have nothing", .coerciveControl),
    ("he checks my phone every night", .coerciveControl),
    ("I am not allowed to see my friends", .coerciveControl),
    ("sometimes I want to hurt him", .harmToOthers),
]

let mustNotFlag: [String] = [
    "my partner would never hit me",
    "I would never kill myself",
    "we had a really good day together",
    "I could kill him for eating my leftovers",   // hyperbole, accepted false negative risk
    "I want to die laughing at that joke",         // hyperbole
]

let mustBeWatch: [String] = [
    "what is the point anymore",
    "I cannot do this anymore",
]

var fails = 0

for (text, expected) in mustFlag {
    let v = SafetyClassifier.classify(text)
    let ok = v.isCrisis && v.category == expected
    if !ok {
        print("FAIL should flag [\\(expected.rawValue)]: \\"\\(text)\\" -> got \\(v.category.rawValue) sev \\(v.severity)")
        fails += 1
    }
}

for text in mustNotFlag {
    let v = SafetyClassifier.classify(text)
    if v.isCrisis {
        print("FAIL false positive: \\"\\(text)\\" -> \\(v.category.rawValue) sev \\(v.severity) (matched: \\(v.matchedPhrase ?? "-"))")
        fails += 1
    }
}

for text in mustBeWatch {
    let v = SafetyClassifier.classify(text)
    if v.severity != 1 {
        print("FAIL should be watch-only: \\"\\(text)\\" -> sev \\(v.severity)")
        fails += 1
    }
}

let total = mustFlag.count + mustNotFlag.count + mustBeWatch.count
print(fails == 0 ? "ALL \\(total) CHECKS PASSED" : "\\(fails) of \\(total) CHECKS FAILED")
exit(fails == 0 ? 0 : 1)
''')

result = subprocess.run(["swift", str(OUT)], capture_output=True, text=True, timeout=300)
print(result.stdout.strip())
if result.returncode != 0:
    print(result.stderr.strip()[-1500:])
sys.exit(result.returncode)
