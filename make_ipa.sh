#!/bin/bash
#
# Builds a distributable Tether.ipa.
#
# ┌──────────────────────────────────────────────────────────────────────┐
# │ THIS REQUIRES A PAID APPLE DEVELOPER ACCOUNT ($99/yr).               │
# │                                                                      │
# │ A free personal team CANNOT produce a shareable IPA. Apple issues    │
# │ free provisioning profiles that are locked to your own device's      │
# │ UDID and expire in 7 days, so the resulting .app will refuse to      │
# │ launch on any other iPhone. There is no workaround.                  │
# │                                                                      │
# │ To test on a SECOND iPhone with a free account, see README-DEVICE.md │
# └──────────────────────────────────────────────────────────────────────┘
#
# Usage:
#   ./make_ipa.sh                     # development IPA (registered devices)
#   ./make_ipa.sh ad-hoc              # ad-hoc IPA (registered devices)
#   ./make_ipa.sh app-store           # App Store Connect upload
#
# Requires: TEAM_ID env var, or edit TEAM_ID below.

set -euo pipefail

cd "$(dirname "$0")"

TEAM_ID="${TEAM_ID:-}"
METHOD="${1:-development}"

if [ -z "$TEAM_ID" ]; then
  echo "ERROR: set your Apple Developer Team ID first."
  echo ""
  echo "  Find it at https://developer.apple.com/account → Membership"
  echo "  Then run:  TEAM_ID=ABCDE12345 ./make_ipa.sh"
  echo ""
  exit 1
fi

echo "==> Regenerating the Xcode project from sources"
python3 make_xcodeproj.py

ARCHIVE="build/Tether.xcarchive"
EXPORT_DIR="build/ipa"
EXPORT_PLIST="build/ExportOptions.plist"

echo "==> Archiving (this takes a minute)"
rm -rf "$ARCHIVE" "$EXPORT_DIR"
xcodebuild archive \
  -project Tether.xcodeproj \
  -scheme Tether \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  | grep -E "error:|warning: .*sign|ARCHIVE SUCCEEDED|ARCHIVE FAILED" || true

if [ ! -d "$ARCHIVE" ]; then
  echo "ERROR: archive failed. Open the project in Xcode and check signing."
  exit 1
fi

echo "==> Writing export options ($METHOD)"
cat > "$EXPORT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${METHOD}</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> Exporting IPA"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  | grep -E "error:|EXPORT SUCCEEDED|EXPORT FAILED" || true

if [ -f "$EXPORT_DIR/Tether.ipa" ]; then
  SIZE=$(du -h "$EXPORT_DIR/Tether.ipa" | cut -f1)
  echo ""
  echo "✅  $EXPORT_DIR/Tether.ipa  ($SIZE)"
  echo ""
  case "$METHOD" in
    development|ad-hoc)
      echo "Install on a registered device with:"
      echo "  Apple Configurator 2, or Xcode → Window → Devices and Simulators → +"
      echo ""
      echo "Note: the device's UDID must be registered in your developer account."
      ;;
    app-store)
      echo "Upload to App Store Connect with:"
      echo "  xcrun altool --upload-app -f $EXPORT_DIR/Tether.ipa \\"
      echo "    -t ios --apiKey YOUR_KEY --apiIssuer YOUR_ISSUER"
      echo "  ...or open Transporter.app and drag it in."
      ;;
  esac
else
  echo "ERROR: no IPA produced. Check the export log above."
  exit 1
fi
