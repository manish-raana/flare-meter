#!/bin/sh
# Builds your own Release copy, signed with your Apple ID's free Personal Team (CFU_TEAM_ID in Config.xcconfig), and
# installs it in /Applications, so the menu bar app and widget run without Xcode. No paid developer account is needed.
# For the signed and notarized download, use scripts/release.sh.
# The Apple Development certificate lasts a year; run this again after Xcode renews it (or after any code change).
set -eu
cd "$(dirname "$0")/.."

APP_NAME=FlareMeter.app
DEST="/Applications/$APP_NAME"
BUILT="build/Build/Products/Release/$APP_NAME"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

xcodegen generate
xcodebuild -project FlareMeter.xcodeproj -scheme FlareMeter -configuration Release \
  -derivedDataPath build -allowProvisioningUpdates -quiet build
codesign --verify --deep --strict "$BUILT"

pkill -x FlareMeter 2>/dev/null || true
pkill -x CloudflareUsage 2>/dev/null || true
pkill -f "$APP_NAME/Contents/PlugIns/FlareMeterWidget.appex" 2>/dev/null || true
rm -rf "$DEST"
# The app was called Cloudflare Usage before it became FlareMeter.
rm -rf /Applications/CloudflareUsage.app
ditto "$BUILT" "$DEST"

# Only the installed copy should provide the widget: forget the build folder's and Xcode's debug copies.
"$LSREGISTER" -u "$BUILT" 2>/dev/null || true
find "$HOME/Library/Developer/Xcode/DerivedData" -path '*/Build/Products/*' -name "$APP_NAME" -maxdepth 5 \
  -exec "$LSREGISTER" -u {} \; 2>/dev/null || true
"$LSREGISTER" -f -R "$DEST"

open "$DEST"
echo "Installed $DEST, signed by $(codesign -dvv "$DEST" 2>&1 | sed -n 's/^Authority=//p' | head -1)"
