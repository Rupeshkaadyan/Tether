#!/usr/bin/env python3
"""Generate a VALID Xcode project for Tether from Swift sources."""
import os, shutil, pathlib, uuid

SRC = pathlib.Path("/Users/rupesh/WorkBuddy AI/2026-09-17-18-08-02/TetherApp/Tether")
DST = pathlib.Path("/Users/rupesh/WorkBuddy AI/2026-09-17-18-08-02/TetherApp")
NAME = "Tether"

# ---- 1. Collect Swift sources (in place) ----
swift_files = []
for dirpath, dirnames, filenames in os.walk(SRC):
    dirnames[:] = [d for d in dirnames if not d.endswith(".xcodeproj")]
    rel = pathlib.Path(dirpath).relative_to(SRC)
    for fn in filenames:
        if not fn.endswith(".swift"):
            continue
        rel_path = (rel / fn) if str(rel) != "." else pathlib.Path(fn)
        swift_files.append(rel_path)

swift_files.sort(key=lambda p: str(p).lower())
print(f"Found {len(swift_files)} Swift files")

# Asset catalogs are resources, not sources.
asset_dirs = []
for dirpath, dirnames, _ in os.walk(SRC):
    for d in list(dirnames):
        if d.endswith(".xcassets"):
            asset_dirs.append(pathlib.Path(dirpath).relative_to(SRC) / d)
    dirnames[:] = [d for d in dirnames if not d.endswith(".xcassets")]
asset_dirs.sort(key=lambda x: str(x).lower())
print(f"Found {len(asset_dirs)} asset catalog(s)")

all_files = swift_files + asset_dirs

# ---- 2. UUID helpers ----
_ctr = [0]
def uid():
    _ctr[0] += 1
    return f"{_ctr[0]:024X}"

def q(v):
    """Quote a plist value if needed."""
    s = str(v)
    if s in ("YES", "NO") or s.isdigit() or s.replace(".", "", 1).isdigit():
        return s
    if s and all(c.isalnum() or c in "_./" for c in s) and not s[0].isdigit():
        return s
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'

# ---- 3. Assign UUIDs ----
U = {}
U["project"]    = uid()
U["target"]     = uid()
U["product"]    = uid()   # .app file ref
U["mainGroup"]  = uid()
U["prodGroup"]  = uid()
U["srcGroup"]   = uid()
U["srcPhase"]   = uid()
U["fwPhase"]    = uid()
U["resPhase"]   = uid()
U["projList"]   = uid()
U["targList"]   = uid()
U["projDebug"]  = uid()
U["projRelease"]= uid()
U["targDebug"]  = uid()
U["targRelease"]= uid()

file_refs, build_files = {}, {}
for p in swift_files + asset_dirs:
    file_refs[p] = uid()
    build_files[p] = uid()

# ---- 4. Build group tree from folders ----
tree = {}
for p in all_files:
    node = tree
    for part in p.parts[:-1]:
        node = node.setdefault(part, {})
    node[p.name] = None

group_ids = {}
def emit(node, depth):
    """Return list of (child_uuid, comment) and emit group blocks."""
    lines, children = [], []
    for key in sorted(node.keys(), key=lambda k: (node[k] is not None, k.lower())):
        if node[key] is None:  # a file
            p = pathlib.Path(key)
            for full in all_files:
                if full.name == key:
                    p = full
                    break
            children.append((file_refs[p], key))
        else:                  # a folder
            gid = uid()
            group_ids[key] = gid
            sub_lines, sub_children = emit(node[key], depth + 1)
            lines.extend(sub_lines)
            children.append((gid, key))
            lines.append(f"\t\t{gid} /* {key} */ = {{")
            lines.append("\t\t\tisa = PBXGroup;")
            lines.append("\t\t\tchildren = (")
            for cu, cn in sub_children:
                lines.append(f"\t\t\t\t{cu} /* {cn} */,")
            lines.append("\t\t\t);")
            lines.append(f"\t\t\tpath = {q(key)};")
            lines.append("\t\t\tsourceTree = \"<group>\";")
            lines.append("\t\t};")
    return lines, children

sub_lines, root_children = emit(tree, 0)

# ---- 5. Build settings ----
proj_common = [
    ("ALWAYS_SEARCH_USER_PATHS", "NO"),
    ("CLANG_ANALYZER_NONNULL", "YES"),
    ("CLANG_ENABLE_MODULES", "YES"),
    ("CLANG_ENABLE_OBJC_ARC", "YES"),
    ("COPY_PHASE_STRIP", "NO"),
    ("ENABLE_STRICT_OBJC_MSGSEND", "YES"),
    ("GCC_C_LANGUAGE_STANDARD", "gnu17"),
    ("GCC_NO_COMMON_BLOCKS", "YES"),
    ("GCC_WARN_UNDECLARED_SELECTOR", "YES"),
    ("GCC_WARN_UNINITIALIZED_AUTOS", "YES"),
    ("GCC_WARN_UNUSED_FUNCTION", "YES"),
    ("GCC_WARN_UNUSED_VARIABLE", "YES"),
    ("IPHONEOS_DEPLOYMENT_TARGET", "17.0"),
    ("MTL_ENABLE_DEBUG_INFO", "INCLUDE_SOURCE"),
    ("MTL_FAST_MATH", "YES"),
    ("SDKROOT", "iphoneos"),
    ("SWIFT_EMIT_LOC_STRINGS", "YES"),
    ("SWIFT_VERSION", "5.9"),
]
proj_debug = proj_common + [
    ("DEBUG_INFORMATION_FORMAT", "dwarf"),
    ("ENABLE_TESTABILITY", "YES"),
    ("GCC_OPTIMIZATION_LEVEL", "0"),
    ("GCC_PREPROCESSOR_DEFINITIONS", ("DEBUG=1", "$(inherited)")),
    ("ONLY_ACTIVE_ARCH", "YES"),
    ("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "DEBUG $(inherited)"),
    ("SWIFT_OPTIMIZATION_LEVEL", "-Onone"),
]
proj_release = proj_common + [
    ("DEBUG_INFORMATION_FORMAT", "dwarf-with-dsym"),
    ("ENABLE_NS_ASSERTIONS", "NO"),
    ("MTL_ENABLE_DEBUG_INFO", "NO"),
    ("SWIFT_COMPILATION_MODE", "wholemodule"),
    ("SWIFT_OPTIMIZATION_LEVEL", "-O"),
    ("VALIDATE_PRODUCT", "YES"),
]

targ_common = [
    ("CODE_SIGN_STYLE", "Automatic"),
    ("CURRENT_PROJECT_VERSION", "1"),
    ("ENABLE_PREVIEWS", "YES"),
    ("GENERATE_INFOPLIST_FILE", "YES"),
    ("INFOPLIST_KEY_UIApplicationSceneManifest_Generation", "YES"),
    ("INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents", "YES"),
    ("INFOPLIST_KEY_UILaunchScreen_Generation", "YES"),
    ("INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad",
     "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"),
    ("INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone",
     "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"),
    ("IPHONEOS_DEPLOYMENT_TARGET", "17.0"),
    ("LD_RUNPATH_SEARCH_PATHS", ("$(inherited)", "@executable_path/Frameworks")),
    ("MARKETING_VERSION", "1.0"),
    ("INFOPLIST_KEY_NSMicrophoneUsageDescription",
     "Tether uses the microphone only when you tap the mic to dictate. Your voice is transcribed on this device and is never uploaded."),
    ("INFOPLIST_KEY_NSSpeechRecognitionUsageDescription",
     "Tether uses speech recognition to turn your dictation into text. Recognition runs on this device."),
    ("ASSETCATALOG_COMPILER_APPICON_NAME", "AppIcon"),
    ("ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME", "AccentColor"),
    ("ASSETCATALOG_COMPILER_APPICON_NAME", "AppIcon"),
    ("ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME", "AccentColor"),
    ("OTHER_SWIFT_FLAGS", "-disable-sandbox"),
    ("PRODUCT_BUNDLE_IDENTIFIER", "com.tethercouples.app"),
    ("PRODUCT_NAME", "$(TARGET_NAME)"),
    ("SDKROOT", "iphoneos"),
    ("SWIFT_EMIT_LOC_STRINGS", "YES"),
    ("SWIFT_VERSION", "5.9"),
    ("TARGETED_DEVICE_FAMILY", "1"),
]
targ_debug = targ_common + [("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "DEBUG $(inherited)"),
                            ("SWIFT_OPTIMIZATION_LEVEL", "-Onone")]
targ_release = targ_common + [("SWIFT_OPTIMIZATION_LEVEL", "-O"),
                              ("VALIDATE_PRODUCT", "YES")]

def settings_block(settings, indent):
    out = [f"{indent}buildSettings = {{"]
    for k, v in settings:
        if isinstance(v, tuple):
            out.append(f"{indent}\t{k} = (")
            for item in v:
                out.append(f"{indent}\t\t{q(item)},")
            out.append(f"{indent}\t);")
        else:
            out.append(f"{indent}\t{k} = {q(v)};")
    out.append(f"{indent}}};")
    return out

# ---- 6. Assemble pbxproj ----
L = []
a = L.append
a("// !$*UTF8*$!")
a("{")
a("\tarchiveVersion = 1;")
a("\tclasses = {")
a("\t};")
a("\tobjectVersion = 56;")
a("\tobjects = {")
a("")

a("/* Begin PBXBuildFile section */")
for p in swift_files:
    a(f"\t\t{build_files[p]} /* {p.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[p]} /* {p.name} */; }};")
for p in asset_dirs:
    a(f"\t\t{build_files[p]} /* {p.name} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_refs[p]} /* {p.name} */; }};")
a("/* End PBXBuildFile section */")
a("")

a("/* Begin PBXFileReference section */")
a(f"\t\t{U['product']} /* {NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
for p in swift_files:
    a(f"\t\t{file_refs[p]} /* {p.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q(p.name)}; sourceTree = \"<group>\"; }};")
for p in asset_dirs:
    a(f"\t\t{file_refs[p]} /* {p.name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = {q(p.name)}; sourceTree = \"<group>\"; }};")
a("/* End PBXFileReference section */")
a("")

a("/* Begin PBXFrameworksBuildPhase section */")
a(f"\t\t{U['fwPhase']} /* Frameworks */ = {{")
a("\t\t\tisa = PBXFrameworksBuildPhase;")
a("\t\t\tbuildActionMask = 2147483647;")
a("\t\t\tfiles = (")
a("\t\t\t);")
a("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
a("\t\t};")
a("/* End PBXFrameworksBuildPhase section */")
a("")

a("/* Begin PBXGroup section */")
for line in sub_lines:
    a(line)
a(f"\t\t{U['srcGroup']} /* Tether */ = {{")
a("\t\t\tisa = PBXGroup;")
a("\t\t\tchildren = (")
for cu, cn in root_children:
    a(f"\t\t\t\t{cu} /* {cn} */,")
a("\t\t\t);")
a("\t\t\tpath = Tether;")
a("\t\t\tsourceTree = \"<group>\";")
a("\t\t};")
a(f"\t\t{U['mainGroup']} = {{")
a("\t\t\tisa = PBXGroup;")
a("\t\t\tchildren = (")
a(f"\t\t\t\t{U['srcGroup']} /* Tether */,")
a("\t\t\t);")
a("\t\t\tsourceTree = \"<group>\";")
a("\t\t};")
a(f"\t\t{U['prodGroup']} /* Products */ = {{")
a("\t\t\tisa = PBXGroup;")
a("\t\t\tchildren = (")
a(f"\t\t\t\t{U['product']} /* {NAME}.app */,")
a("\t\t\t);")
a("\t\t\tname = Products;")
a("\t\t\tsourceTree = \"<group>\";")
a("\t\t};")
a("/* End PBXGroup section */")
a("")

a("/* Begin PBXNativeTarget section */")
a(f"\t\t{U['target']} /* {NAME} */ = {{")
a("\t\t\tisa = PBXNativeTarget;")
a(f"\t\t\tbuildConfigurationList = {U['targList']} /* Build configuration list for PBXNativeTarget \"{NAME}\" */;")
a("\t\t\tbuildPhases = (")
a(f"\t\t\t\t{U['srcPhase']} /* Sources */,")
a(f"\t\t\t\t{U['fwPhase']} /* Frameworks */,")
a(f"\t\t\t\t{U['resPhase']} /* Resources */,")
a("\t\t\t);")
a("\t\t\tbuildRules = (")
a("\t\t\t);")
a("\t\t\tdependencies = (")
a("\t\t\t);")
a(f"\t\t\tname = {NAME};")
a(f"\t\t\tproductName = {NAME};")
a(f"\t\t\tproductReference = {U['product']} /* {NAME}.app */;")
a("\t\t\tproductType = \"com.apple.product-type.application\";")
a("\t\t};")
a("/* End PBXNativeTarget section */")
a("")

a("/* Begin PBXProject section */")
a(f"\t\t{U['project']} /* Project object */ = {{")
a("\t\t\tisa = PBXProject;")
a("\t\t\tattributes = {")
a("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
a("\t\t\t\tLastSwiftUpdateCheck = 1500;")
a("\t\t\t\tLastUpgradeCheck = 1500;")
a("\t\t\t\tTargetAttributes = {")
a(f"\t\t\t\t\t{U['target']} = {{")
a("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
a("\t\t\t\t\t};")
a("\t\t\t\t};")
a("\t\t\t};")
a(f"\t\t\tbuildConfigurationList = {U['projList']} /* Build configuration list for PBXProject \"{NAME}\" */;")
a("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
a("\t\t\tdevelopmentRegion = en;")
a("\t\t\thasScannedForEncodings = 0;")
a("\t\t\tknownRegions = (")
a("\t\t\t\ten,")
a("\t\t\t\tBase,")
a("\t\t\t);")
a(f"\t\t\tmainGroup = {U['mainGroup']};")
a(f"\t\t\tproductRefGroup = {U['prodGroup']} /* Products */;")
a("\t\t\tprojectDirPath = \"\";")
a("\t\t\tprojectRoot = \"\";")
a("\t\t\ttargets = (")
a(f"\t\t\t\t{U['target']} /* {NAME} */,")
a("\t\t\t);")
a("\t\t};")
a("/* End PBXProject section */")
a("")

a("/* Begin PBXResourcesBuildPhase section */")
a(f"\t\t{U['resPhase']} /* Resources */ = {{")
a("\t\t\tisa = PBXResourcesBuildPhase;")
a("\t\t\tbuildActionMask = 2147483647;")
a("\t\t\tfiles = (")
for p in asset_dirs:
    a(f"\t\t\t\t{build_files[p]} /* {p.name} in Resources */,")
a("\t\t\t);")
a("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
a("\t\t};")
a("/* End PBXResourcesBuildPhase section */")
a("")

a("/* Begin PBXSourcesBuildPhase section */")
a(f"\t\t{U['srcPhase']} /* Sources */ = {{")
a("\t\t\tisa = PBXSourcesBuildPhase;")
a("\t\t\tbuildActionMask = 2147483647;")
a("\t\t\tfiles = (")
for p in swift_files:
    a(f"\t\t\t\t{build_files[p]} /* {p.name} in Sources */,")
a("\t\t\t);")
a("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
a("\t\t};")
a("/* End PBXSourcesBuildPhase section */")
a("")

a("/* Begin XCBuildConfiguration section */")
for cfg_uuid, cfg_name, cfg_settings in [
    (U["projDebug"], "Debug", proj_debug),
    (U["projRelease"], "Release", proj_release),
    (U["targDebug"], "Debug", targ_debug),
    (U["targRelease"], "Release", targ_release),
]:
    a(f"\t\t{cfg_uuid} /* {cfg_name} */ = {{")
    a("\t\t\tisa = XCBuildConfiguration;")
    for line in settings_block(cfg_settings, "\t\t\t"):
        a(line)
    a(f"\t\t\tname = {cfg_name};")
    a("\t\t};")
a("/* End XCBuildConfiguration section */")
a("")

a("/* Begin XCConfigurationList section */")
a(f"\t\t{U['projList']} /* Build configuration list for PBXProject \"{NAME}\" */ = {{")
a("\t\t\tisa = XCConfigurationList;")
a("\t\t\tbuildConfigurations = (")
a(f"\t\t\t\t{U['projDebug']} /* Debug */,")
a(f"\t\t\t\t{U['projRelease']} /* Release */,")
a("\t\t\t);")
a("\t\t\tdefaultConfigurationIsVisible = 0;")
a("\t\t\tdefaultConfigurationName = Release;")
a("\t\t};")
a(f"\t\t{U['targList']} /* Build configuration list for PBXNativeTarget \"{NAME}\" */ = {{")
a("\t\t\tisa = XCConfigurationList;")
a("\t\t\tbuildConfigurations = (")
a(f"\t\t\t\t{U['targDebug']} /* Debug */,")
a(f"\t\t\t\t{U['targRelease']} /* Release */,")
a("\t\t\t);")
a("\t\t\tdefaultConfigurationIsVisible = 0;")
a("\t\t\tdefaultConfigurationName = Release;")
a("\t\t};")
a("/* End XCConfigurationList section */")
a("\t};")
a(f"\trootObject = {U['project']} /* Project object */;")
a("}")

# ---- 7. Write files ----
xp = DST / f"{NAME}.xcodeproj"
if not xp.exists():
    xp.mkdir(parents=True)
(xp / "project.pbxproj").write_text("\n".join(L) + "\n", encoding="utf-8")

xcw = xp / "project.xcworkspace"
if not xcw.exists():
    xcw.mkdir(parents=True)
(xcw / "contents.xcworkspacedata").write_text(
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<Workspace\n   version = "1.0">\n'
    '   <FileRef\n      location = "self:">\n'
    '   </FileRef>\n'
    '</Workspace>\n', encoding="utf-8")

print(f"Wrote: {xp}")
print("VALIDATE NOW with: plutil -lint " + str(xp / "project.pbxproj"))
