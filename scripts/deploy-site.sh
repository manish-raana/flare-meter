#!/bin/sh
# Builds the marketing site (web/, Next.js static export) and deploys it to Cloudflare as static files at
# https://flaremeter.app (web/wrangler.jsonc).
# Needs `npx wrangler login` once.
set -eu
cd "$(dirname "$0")/../web"
npm ci
npm run build
npx wrangler deploy
