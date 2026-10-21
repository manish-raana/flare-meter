// Cloudflare's published limits and prices that FlareMeter measures against, mirrored from the app
// (Shared/Metrics.swift). Update both together, with `asOf`.

export const asOf = "October 2026";
export const lastReviewed = "2026-10-10";

export type Limit = {
  product: string;
  metric: string;
  /** Workers Free, per day (00:00 UTC reset). */
  freeDaily?: string;
  /** Workers Paid, included per month. */
  paidIncluded?: string;
  /** Workers Paid, past the included amount. */
  paidOverage?: string;
};

export const limits: Limit[] = [
  { product: "Workers", metric: "Requests", freeDaily: "100,000", paidIncluded: "10 million", paidOverage: "$0.30 per million" },
  { product: "Durable Objects", metric: "Requests", freeDaily: "100,000", paidIncluded: "1 million", paidOverage: "$0.15 per million" },
  { product: "Durable Objects", metric: "Rows read (SQLite)", freeDaily: "5 million", paidIncluded: "25 billion", paidOverage: "$0.001 per million" },
  { product: "Durable Objects", metric: "Rows written (SQLite)", freeDaily: "100,000", paidIncluded: "50 million", paidOverage: "$1.00 per million" },
  { product: "Durable Objects", metric: "Stored data", freeDaily: "5 GB (total)", paidIncluded: "5 GB" },
  { product: "Workers KV", metric: "Reads", freeDaily: "100,000", paidIncluded: "10 million", paidOverage: "$0.50 per million" },
  { product: "Workers KV", metric: "Writes, deletes and lists", freeDaily: "1,000", paidIncluded: "1 million", paidOverage: "$5.00 per million" },
  { product: "D1", metric: "Rows read", freeDaily: "5 million", paidIncluded: "25 billion", paidOverage: "$0.001 per million" },
  { product: "D1", metric: "Rows written", freeDaily: "100,000", paidIncluded: "50 million", paidOverage: "$1.00 per million" },
  { product: "Workers AI", metric: "Neurons", freeDaily: "10,000", paidIncluded: "10,000 per day", paidOverage: "$0.011 per 1,000" },
];

export const sources = [
  { label: "Workers pricing", url: "https://developers.cloudflare.com/workers/platform/pricing/" },
  { label: "Workers limits", url: "https://developers.cloudflare.com/workers/platform/limits/" },
  { label: "Durable Objects pricing", url: "https://developers.cloudflare.com/durable-objects/platform/pricing/" },
  { label: "KV pricing", url: "https://developers.cloudflare.com/kv/platform/pricing/" },
  { label: "D1 pricing", url: "https://developers.cloudflare.com/d1/platform/pricing/" },
  { label: "Workers AI pricing", url: "https://developers.cloudflare.com/workers-ai/platform/pricing/" },
];
