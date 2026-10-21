import { faqs } from "./faqs";
import { guides } from "./guides";
import { asOf, limits } from "./limits";
import { site } from "./site";

// llms.txt (https://llmstxt.org): a plain summary of the site for AI assistants and answer engines.

const pages = [
  { path: "/guides", title: "Guides", note: "Cloudflare Workers limits, pricing and monitoring" },
  { path: "/about", title: "About", note: "who makes FlareMeter and how it works" },
  { path: "/contact", title: "Contact", note: `support at ${site.supportEmail}` },
  { path: "/terms", title: "Terms of Use", note: `free, open source (${site.license}), provided as is` },
  { path: "/privacy", title: "Privacy", note: "no accounts, analytics or tracking" },
];

export function llmsTxt() {
  return `# ${site.name}

> ${site.name} is a macOS menu bar app and set of desktop widgets that show a Cloudflare account's usage of Workers, Durable Objects, KV, D1 and Workers AI against its plan's limits (Workers Free daily caps or Workers Paid monthly included amounts, with estimated charges), and sends early-warning notifications. Free and open source (${site.license}). Requires ${site.minimumMacOS} or later. Made by ${site.seller.name}; not affiliated with Cloudflare, Inc.

Key facts:
- Reads usage from Cloudflare's GraphQL Analytics API with a read-only API token (Account Analytics · Read), straight from the Mac. No ${site.name} server, account, analytics or tracking. The token is kept in the macOS Keychain.
- Shows the fullest limit's percentage in the menu bar (a warning cloud past 85%); a panel with every metric; small, medium and large widgets. Refreshes every 15 minutes, on wake, and on demand.
- Early-warning alerts (macOS notifications, checked every 15 minutes while the app runs): a metric reaching a warning level (80% of its limit by default) or its limit; on Workers Paid, estimated charges passing a budget (default $10); and unusual spikes, when a metric runs at 10x or more its usual rate for two readings in a row, such as a runaway Durable Object alarm loop.
- Free: no price, license key, trial or account. Source code: ${site.githubUrl} (${site.license}). Sponsor: ${site.sponsorUrl}

## Guides

${guides.map((g) => `- [${g.title}](${site.url}/guides/${g.slug}): ${g.description}`).join("\n")}

## Product and policies

${pages.map((p) => `- [${p.title}](${site.url}${p.path}): ${p.note}`).join("\n")}

## Optional

- [Full text for LLMs](${site.url}/llms-full.txt): the FAQ and Cloudflare limits table in plain text
`;
}

export function llmsFullTxt() {
  return `${llmsTxt()}
## FAQ

${faqs.map((f) => `### ${f.q}\n\n${f.a}`).join("\n\n")}

## Cloudflare Workers limits ${site.name} measures against (as of ${asOf})

| Product | Metric | Workers Free, per day | Workers Paid, included per month | Workers Paid, past included |
| --- | --- | --- | --- | --- |
${limits.map((l) => `| ${l.product} | ${l.metric} | ${l.freeDaily ?? "-"} | ${l.paidIncluded ?? "-"} | ${l.paidOverage ?? "-"} |`).join("\n")}

Workers Free limits are per account and reset at 00:00 UTC; past them, requests fail (Worker requests return error 1027) and nothing is billed. Workers Paid costs $5 a month minimum and bills usage past the included amounts. Check Cloudflare's pricing pages for current figures: https://developers.cloudflare.com/workers/platform/pricing/
`;
}
