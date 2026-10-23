// Run with: npm test
import assert from "node:assert/strict";
import { test } from "node:test";
import { releaseURL } from "../worker/downloads.ts";

const releases = "https://github.com/manish-raana/flare-meter/releases";

test("FlareMeter.dmg goes to the latest release", () => {
  assert.equal(releaseURL("/FlareMeter.dmg"), `${releases}/latest/download/FlareMeter.dmg`);
});

test("a versioned DMG goes to its own release", () => {
  assert.equal(releaseURL("/downloads/FlareMeter-1.0.dmg"), `${releases}/download/v1.0/FlareMeter-1.0.dmg`);
  assert.equal(releaseURL("/downloads/FlareMeter-1.2.3.dmg"), `${releases}/download/v1.2.3/FlareMeter-1.2.3.dmg`);
});

test("anything else isn't redirected", () => {
  for (const path of ["/downloads/", "/downloads/other.dmg", "/downloads/FlareMeter-1.0.zip", "/downloads/FlareMeter-.dmg", "/FlareMeter.zip"]) {
    assert.equal(releaseURL(path), null, path);
  }
});
