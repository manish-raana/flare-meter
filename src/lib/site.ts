/** Product facts the site shows. The Buy link comes from NEXT_PUBLIC_BUY_URL (the Dodo Payments checkout link). */
export const site = {
  name: "FlareMeter",
  url: "https://flaremeter.pages.dev",
  price: "$4.99",
  buyUrl: process.env.NEXT_PUBLIC_BUY_URL ?? "https://checkout.dodopayments.com/buy/REPLACE_WITH_PRODUCT_ID",
  /** Written by scripts/release.sh. */
  downloadUrl: "/FlareMeter.dmg",
  supportEmail: "mkrana173@gmail.com",
  /** Must match the Activations Limit on the Dodo License Key entitlement. */
  macsPerLicense: 3,
  minimumMacOS: "macOS 14 Sonoma",
  /** Search and share text. */
  title: "FlareMeter: Cloudflare Workers usage in your Mac's menu bar",
  description:
    "A Mac menu bar app and desktop widgets that show your Cloudflare Workers, Durable Objects, KV, D1 and Workers AI usage against your plan's limits. $4.99, one-time.",
  keywords: [
    "Cloudflare Workers usage",
    "Cloudflare usage monitor",
    "Workers Free limits",
    "Workers Paid billing",
    "Durable Objects usage",
    "Cloudflare KV usage",
    "Cloudflare D1 usage",
    "Workers AI neurons",
    "macOS menu bar app",
    "macOS widget",
  ],
  author: { name: "Manish Rana", handle: "@ManishRaanaa", url: "https://x.com/ManishRaanaa" },
};
