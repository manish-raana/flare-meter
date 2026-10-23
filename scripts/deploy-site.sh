#!/bin/sh
# Builds the marketing site (web/, Next.js static export) and deploys it to Cloudflare as static files at
# https://flaremeter.app (web/wrangler.jsonc).
# Needs `npx wrangler login` once.
set -eu
cd "$(dirname "$0")/../web"

# The DMGs ship with the site from web/public/. Warn (don't stop) if one Sparkle's feed lists is missing: the Worker then
# sends that download to GitHub Releases, which only works if scripts/github-release.sh published it.
for path in /FlareMeter.dmg $(sed -n 's|.*url="https://flaremeter.app\(/downloads/[^"]*\)".*|\1|p' public/appcast.xml); do
  [ -f "public$path" ] || echo "Warning: web/public$path is missing; that download will go to GitHub Releases."
done

npm ci
npm run build
npx wrangler deploy
