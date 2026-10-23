#!/bin/sh
# Builds a FlareMeter release for download outside the App Store: Developer ID signing, notarization, a DMG, and the
# Sparkle update feed. Results go to web/public/ (publish with scripts/deploy-site.sh).
#
# Needs, once:
#   - The paid Apple Developer Program team in Config.xcconfig: CFU_TEAM_ID and CFU_KEYCHAIN = YES.
#   - A "Developer ID Application" certificate: Xcode → Settings → Accounts → Manage Certificates → + .
#   - Notarization credentials (an app-specific password from account.apple.com):
#       xcrun notarytool store-credentials flaremeter-notary --apple-id <apple id> --team-id <team id>
#   - Sparkle's signing key in your login Keychain (scripts already made it; account "flaremeter").
#   - Optional: the GitHub CLI, signed in (brew install gh && gh auth login), to also attach the DMG to a GitHub release.
# Each release: raise MARKETING_VERSION and CURRENT_PROJECT_VERSION in project.yml (Sparkle compares the build number).
set -eu
cd "$(dirname "$0")/.."

NOTARY_PROFILE=flaremeter-notary
SITE_URL=https://flaremeter.app
OUT=build/release
VERSION=$(sed -n 's/^ *MARKETING_VERSION: "\(.*\)"/\1/p' project.yml)
BUILD=$(sed -n 's/^ *CURRENT_PROJECT_VERSION: "\(.*\)"/\1/p' project.yml)
# Local.xcconfig, if any, overrides Config.xcconfig; the last setting wins.
CONFIGS="Config.xcconfig $( [ -f Local.xcconfig ] && echo Local.xcconfig )"
TEAM=$(cat $CONFIGS | sed -n 's/^CFU_TEAM_ID = *//p' | tail -1)
KEYCHAIN=$(cat $CONFIGS | sed -n 's/^CFU_KEYCHAIN = *//p' | tail -1)

[ "$KEYCHAIN" = YES ] || { echo "Set CFU_KEYCHAIN = YES (paid team) in Config.xcconfig or Local.xcconfig."; exit 1; }
if [ -f web/public/appcast.xml ] && grep -q "<sparkle:version>$BUILD</sparkle:version>" web/public/appcast.xml; then
  echo "Build $BUILD is already released: raise CURRENT_PROJECT_VERSION in project.yml."; exit 1
fi

rm -rf "$OUT" && mkdir -p "$OUT"
xcodegen generate
xcodebuild archive -project FlareMeter.xcodeproj -scheme FlareMeter -configuration Release \
  -archivePath "$OUT/FlareMeter.xcarchive" -allowProvisioningUpdates -quiet

cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>developer-id</string>
	<key>signingStyle</key><string>automatic</string>
	<key>teamID</key><string>$TEAM</string>
</dict>
</plist>
PLIST
xcodebuild -exportArchive -archivePath "$OUT/FlareMeter.xcarchive" -exportPath "$OUT/export" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" -allowProvisioningUpdates -quiet
APP="$OUT/export/FlareMeter.app"

# Notarize and staple the app itself, so it opens offline too.
ditto -c -k --keepParent "$APP" "$OUT/FlareMeter.zip"
xcrun notarytool submit "$OUT/FlareMeter.zip" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"

# A DMG with the app and an Applications shortcut, signed, notarized and stapled.
DMG="$OUT/FlareMeter-$VERSION.dmg"
mkdir -p "$OUT/dmg" && ditto "$APP" "$OUT/dmg/FlareMeter.app" && ln -s /Applications "$OUT/dmg/Applications"
hdiutil create -volname FlareMeter -srcfolder "$OUT/dmg" -ov -format UDZO "$DMG"
codesign --sign "Developer ID Application" --timestamp "$DMG"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"
spctl --assess --type open --context context:primary-signature --verbose "$DMG"

# Publish: every version under downloads/ (Sparkle's feed lists them), the latest also as FlareMeter.dmg.
mkdir -p web/public/downloads
cp "$DMG" web/public/downloads/
cp "$DMG" web/public/FlareMeter.dmg
SPARKLE_BIN=$(find build/SourcePackages ~/Library/Developer/Xcode/DerivedData -path '*artifacts/sparkle/Sparkle/bin' -type d 2>/dev/null | head -1)
[ -n "$SPARKLE_BIN" ] || { xcodebuild -resolvePackageDependencies -project FlareMeter.xcodeproj -clonedSourcePackagesDirPath build/SourcePackages -quiet; SPARKLE_BIN=build/SourcePackages/artifacts/sparkle/Sparkle/bin; }
"$SPARKLE_BIN/generate_appcast" --account flaremeter --download-url-prefix "$SITE_URL/downloads/" \
  --link "$SITE_URL" -o web/public/appcast.xml web/public/downloads

# Optional: also attach the DMG to a GitHub release (needs the GitHub CLI). The site serves its own copy either way.
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  scripts/github-release.sh "$VERSION" || echo "The GitHub release didn't work; the DMG still ships with the site."
else
  echo "Skipping the GitHub release (no signed-in GitHub CLI); the DMG ships with the site."
fi

echo "Released FlareMeter $VERSION ($BUILD). Commit web/public/, then publish with: scripts/deploy-site.sh"
