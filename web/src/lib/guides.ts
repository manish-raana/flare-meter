/** The guides, for the index page, the sitemap and llms.txt. */
export type GuideInfo = { slug: string; title: string; description: string; updated: string };

export const guides: GuideInfo[] = [
  {
    slug: "cloudflare-workers-free-plan-limits",
    title: "Cloudflare Workers Free plan limits (2026)",
    description:
      "Every daily limit on Workers Free: requests, Durable Objects, KV, D1 and Workers AI, when they reset, and what happens when you hit one.",
    updated: "2026-10-10",
  },
  {
    slug: "cloudflare-workers-paid-pricing",
    title: "Cloudflare Workers Paid pricing explained (2026)",
    description:
      "What the $5 Workers Paid plan includes each month, what you pay past it for requests, Durable Objects, KV, D1 and Workers AI, with worked examples.",
    updated: "2026-10-10",
  },
  {
    slug: "monitor-cloudflare-workers-usage",
    title: "How to monitor Cloudflare Workers usage",
    description:
      "Three ways to see how much of your Cloudflare plan you've used: the dashboard, the GraphQL Analytics API (with queries), and a menu bar meter.",
    updated: "2026-10-21",
  },
];
