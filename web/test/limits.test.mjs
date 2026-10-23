// Run with: npm test
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

const data = JSON.parse(readFileSync(new URL("../../Shared/Limits.json", import.meta.url), "utf8"));
// The app's metric ids (Shared/Metrics.swift), so a typo in Limits.json can't silently drop a limit.
const swift = readFileSync(new URL("../../Shared/Metrics.swift", import.meta.url), "utf8");
const metricIDs = new Set([...swift.matchAll(/MetricSpec\(id: "(\w+)"/g)].map((m) => m[1]));

test("every entry in Limits.json is a metric the app measures", () => {
  assert.ok(metricIDs.size >= 10);
  for (const m of data.metrics) assert.ok(metricIDs.has(m.id), `${m.id} isn't in Shared/Metrics.swift`);
});

test("every entry is complete", () => {
  assert.match(data.asOf, /^[A-Z][a-z]+ \d{4}$/);
  assert.match(data.lastReviewed, /^\d{4}-\d{2}-\d{2}$/);
  for (const m of data.metrics) {
    assert.ok(m.product && m.metric, m.id);
    assert.ok(m.freeDaily !== undefined || m.freeText, `${m.id}: no Free limit`);
    assert.ok(["month", "day"].includes(m.paidIncludedPer), `${m.id}: paidIncludedPer`);
    assert.equal(m.paidPriceUSD === undefined, m.paidPricePer === undefined, `${m.id}: price and unit go together`);
  }
});
