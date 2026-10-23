#!/bin/sh
# Optional: publishes a FlareMeter DMG as a GitHub release: tags v<version> and uploads FlareMeter-<version>.dmg plus a
# copy named FlareMeter.dmg. The site ships its own copy from web/public/; its Worker only sends downloads here when a
# deploy is missing one. scripts/release.sh runs this when the GitHub CLI is signed in. Uses no GitHub Actions.
#
#   scripts/github-release.sh <version> [commit]     e.g. scripts/github-release.sh 1.0 ca30140
#
# Needs the GitHub CLI, signed in: brew install gh && gh auth login
set -eu
cd "$(dirname "$0")/.."

VERSION=${1:?usage: scripts/github-release.sh <version> [commit]}
TARGET=${2:-$(git rev-parse HEAD)}
DMG=web/public/downloads/FlareMeter-$VERSION.dmg
[ -f "$DMG" ] || DMG=build/release/FlareMeter-$VERSION.dmg
[ -f "$DMG" ] || { echo "No FlareMeter-$VERSION.dmg in web/public/downloads/ or build/release/."; exit 1; }
command -v gh >/dev/null || { echo "Install the GitHub CLI: brew install gh && gh auth login"; exit 1; }

LATEST=$(mktemp -d)/FlareMeter.dmg
cp "$DMG" "$LATEST"
gh release create "v$VERSION" "$DMG" "$LATEST" --target "$TARGET" --title "FlareMeter $VERSION" \
  --notes "Download FlareMeter-$VERSION.dmg, or get it from https://flaremeter.app. Existing copies update themselves."
echo "Published v$VERSION: https://github.com/manish-raana/flare-meter/releases/tag/v$VERSION"
