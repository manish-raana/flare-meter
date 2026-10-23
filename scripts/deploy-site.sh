#!/bin/sh
# Builds the marketing site (web/, Next.js static export) and deploys it to Cloudflare as static files at
# https://flaremeter.app (web/wrangler.jsonc).
# Needs `npx wrangler login` once.
set -eu
cd "$(dirname "$0")/../web"

# Every DMG Sparkle's feed lists, and FlareMeter.dmg, must be in public/ or on GitHub Releases, where the Worker sends
# downloads public/ doesn't have. Otherwise existing users couldn't update.
for path in /FlareMeter.dmg $(sed -n 's|.*url="https://flaremeter.app\(/downloads/[^"]*\)".*|\1|p' public/appcast.xml); do
  [ -f "public$path" ] && continue
  case $path in
    /FlareMeter.dmg) url=https://github.com/manish-raana/flare-meter/releases/latest/download/FlareMeter.dmg ;;
    *) file=${path#/downloads/}; v=${file#FlareMeter-}; url=https://github.com/manish-raana/flare-meter/releases/download/v${v%.dmg}/$file ;;
  esac
  curl -fsIL -o /dev/null "$url" || { echo "$path is in neither web/public/ nor GitHub Releases ($url). Run scripts/github-release.sh."; exit 1; }
done

npm ci
npm run build
npx wrangler deploy
