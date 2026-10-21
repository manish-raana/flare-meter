#!/bin/sh
# Renders screenshots from the app's real views (sample data) into marketing/, the README's images into
# docs/images/, and the icon the site shows. (The site draws its share cards itself: web/src/lib/og.tsx.)
set -eu
cd "$(dirname "$0")/.."
xcodegen generate >/dev/null
xcodebuild -project FlareMeter.xcodeproj -scheme FlareMeter -configuration Debug -derivedDataPath build \
  -allowProvisioningUpdates -quiet build
# Sandboxed: render inside the app's container, then copy out.
OUT="$HOME/Library/Containers/com.manishrana.FlareMeter/Data/tmp/marketing"
rm -rf "$OUT"
build/Build/Products/Debug/FlareMeter.app/Contents/MacOS/FlareMeter --render-marketing "$OUT"
"/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister" -u \
  build/Build/Products/Debug/FlareMeter.app 2>/dev/null || true
mkdir -p marketing docs/images
mv "$OUT"/readme-*.png docs/images/
cp "$OUT"/*.png marketing/
cp App/Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png web/public/icon.png
echo "Screenshots in marketing/, README images in docs/images/, the site's icon in web/public/"
