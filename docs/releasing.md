# Releasing FlareMeter

FlareMeter is free and open source (AGPL-3.0). The download at flaremeter.app is a Developer ID-signed, notarized build
of this repository, updated through Sparkle. Support comes from sponsors on
[GitHub Sponsors](https://github.com/sponsors/manish-raana).

## One-time setup

1. **Apple Developer Program** ($99/year). Downloaded apps must be Developer ID-signed and notarized, or macOS blocks
   them. In `Config.xcconfig`: the paid team's `CFU_TEAM_ID` (usually different from the free Personal Team's) and
   `CFU_KEYCHAIN = YES`.
2. **Developer ID certificate**: Xcode → Settings → Accounts → Manage Certificates → + → Developer ID Application.
3. **Notarization credentials**: create an app-specific password at account.apple.com, then
   `xcrun notarytool store-credentials flaremeter-notary --apple-id <apple id> --team-id <team id>`.
4. **Sparkle signing key**: already created in your login Keychain (account `flaremeter`); its public half is
   `CFU_SPARKLE_PUBLIC_KEY`. **Back it up**: `build/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys --account
   flaremeter -x flaremeter-sparkle-key.txt`, store the file somewhere safe, then delete it. Without it you can't ship
   updates to existing users.
5. **Website**: `npx wrangler login` once; `scripts/deploy-site.sh` builds `web/` and deploys it to
   flaremeter.app (see "Domain and website" below).
6. **GitHub Sponsors**: set up a Sponsors profile for `manish-raana` at github.com/sponsors. `.github/FUNDING.yml`
   adds the Sponsor button to the repository, and the app's Settings, the README and the website link to it.

## Domain and website

flaremeter.app is registered at Spaceship; its DNS is on Cloudflare, and the site is static files served by
Cloudflare (`web/wrangler.jsonc`).

1. Cloudflare dashboard → Add a domain → `flaremeter.app` (Free plan). Cloudflare shows two nameservers.
2. Spaceship → Domains → flaremeter.app → Nameservers → Custom → paste Cloudflare's two nameservers.
3. When Cloudflare shows the domain as Active: `npx wrangler login`, then `scripts/deploy-site.sh`. It attaches to
   `flaremeter.app`.
4. Optional: Rules → Redirect Rules → redirect `www.flaremeter.app/*` to `https://flaremeter.app/${1}` (301).

The app's update feed (`CFU_APPCAST_URL`) points at this domain: keep it working for as long as anyone runs FlareMeter.

## Support email

Support is by email (`support@flaremeter.app`) and GitHub issues. In Cloudflare → flaremeter.app → Email → Email
Routing, enable it, add your Gmail as a destination (confirm the verification email), and add a rule
`support@flaremeter.app` → your Gmail. To reply from that address in Gmail, add it under Settings → Accounts →
"Send mail as".

## Each release

1. Check the limits and prices in `Shared/Limits.json` against Cloudflare's pricing pages; update `asOf` and
   `lastReviewed`. The app and the website both read this file.
2. Raise `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`.
3. `scripts/release.sh`: archives, signs with Developer ID, notarizes and staples the app and DMG, puts the DMG in
   `web/public/downloads/` and `web/public/FlareMeter.dmg`, and updates `web/public/appcast.xml`. If the GitHub CLI is
   signed in (`brew install gh && gh auth login`), it also tags `v<version>` and attaches the DMG to a GitHub release
   (`scripts/github-release.sh`); otherwise it skips that. Nothing here uses GitHub Actions.
4. Commit `web/public/` and the version bump, and push.
5. `scripts/deploy-site.sh`. The DMGs ship with the site. Existing users get the update through Sparkle; new users
   download `FlareMeter.dmg`.

If a deploy is ever missing a DMG, the site's Worker (`web/worker/`) redirects that download to the GitHub release of
the same version, and `deploy-site.sh` warns about it first.

## Launch checklist

- [ ] Repository public, with `LICENSE` and the README's images showing.
- [ ] GitHub Sponsors profile live, so the Sponsor links work.
- [ ] Site deployed, and `FlareMeter.dmg` downloads and opens without warnings.
- [ ] Alerts tried end to end: Settings → Alerts → Send Test Notification, and clicking it opens the dashboard.
- [ ] support@flaremeter.app forwards to your inbox.
- [ ] Post: Cloudflare Discord (Workers channels), r/CloudFlare, Show HN, X/Bluesky with a short demo clip.
