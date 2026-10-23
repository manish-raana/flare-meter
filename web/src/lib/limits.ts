// Cloudflare's published limits and prices that FlareMeter measures against. They come from Shared/Limits.json, the
// same file the app reads, so the site and the app can't disagree. Update them there.
import data from "../../../Shared/Limits.json";

export const asOf = data.asOf;
export const lastReviewed = data.lastReviewed;
/** The Workers Paid subscription, per month. */
export const paidBaseUSD = data.paidBaseUSD;

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

type Entry = {
  product: string;
  metric: string;
  unit?: string;
  total?: boolean;
  freeDaily?: number;
  freeText?: string;
  paidIncluded?: number;
  paidIncludedPer?: string;
  paidPriceUSD?: number;
  paidPricePer?: number;
};

/** "1,000", "10 million", "25 billion", or "5 GB" for bytes. */
export function amount(n: number, unit?: string) {
  if (unit === "bytes") return `${n / 1e9} GB`;
  if (n >= 1e9) return `${n / 1e9} billion`;
  if (n >= 1e6) return `${n / 1e6} million`;
  return n.toLocaleString("en-US");
}

/** "$0.30 per million", "$0.011 per 1,000". */
export function price(usd: number, per: number) {
  const digits = usd < 0.01 ? 3 : 2;
  return `$${usd.toFixed(Math.max(digits, (usd.toString().split(".")[1] ?? "").length))} per ${per === 1e6 ? "million" : per.toLocaleString("en-US")}`;
}

function toLimit(e: Entry): Limit {
  return {
    product: e.product,
    metric: e.metric,
    freeDaily: e.freeText ?? (e.freeDaily === undefined ? undefined : amount(e.freeDaily, e.unit) + (e.total ? " (total)" : "")),
    paidIncluded:
      e.paidIncluded === undefined
        ? undefined
        : amount(e.paidIncluded, e.unit) + (e.paidIncludedPer === "day" ? " per day" : ""),
    paidOverage: e.paidPriceUSD === undefined || e.paidPricePer === undefined ? undefined : price(e.paidPriceUSD, e.paidPricePer),
  };
}

export const limits: Limit[] = (data.metrics as Entry[]).map(toLimit);

export const sources = [
  { label: "Workers pricing", url: "https://developers.cloudflare.com/workers/platform/pricing/" },
  { label: "Workers limits", url: "https://developers.cloudflare.com/workers/platform/limits/" },
  { label: "Durable Objects pricing", url: "https://developers.cloudflare.com/durable-objects/platform/pricing/" },
  { label: "KV pricing", url: "https://developers.cloudflare.com/kv/platform/pricing/" },
  { label: "D1 pricing", url: "https://developers.cloudflare.com/d1/platform/pricing/" },
  { label: "Workers AI pricing", url: "https://developers.cloudflare.com/workers-ai/platform/pricing/" },
];
