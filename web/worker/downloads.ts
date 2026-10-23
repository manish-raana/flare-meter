/** Where scripts/github-release.sh uploads each version's DMG, and a copy named FlareMeter.dmg for the latest. */
const RELEASES = "https://github.com/manish-raana/flare-meter/releases";

/**
 * The GitHub Releases copy of a DMG the static files don't have: /FlareMeter.dmg is the latest release's, and
 * /downloads/FlareMeter-1.2.dmg (Sparkle's feed) is v1.2's.
 */
export function releaseURL(pathname: string): string | null {
  if (pathname === "/FlareMeter.dmg") return `${RELEASES}/latest/download/FlareMeter.dmg`;
  const match = /^\/downloads\/(FlareMeter-(\d+(?:\.\d+)*)\.dmg)$/.exec(pathname);
  return match ? `${RELEASES}/download/v${match[2]}/${match[1]}` : null;
}
