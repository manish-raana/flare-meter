import { site } from "./site";

/** Shown in the FAQ section and given to search engines as FAQPage data. */
export const faqs = [
  { q: "Is it really free?", a: `Yes. ${site.name} is open source under the ${site.license}, and the signed, notarized download is free too. There's no license key, trial or account. If it helps you, you can sponsor its development on GitHub.` },
  { q: "Which Cloudflare plans does it support?", a: "Workers Free (daily limits, reset at 00:00 UTC) and Workers Paid (monthly included amounts, with estimated charges past them). Pick yours in Settings." },
  { q: "What do the alerts warn me about?", a: "A metric reaching your warning level (80% of its limit by default) and hitting the limit; on Workers Paid, estimated charges passing a budget you set ($10 by default); and unusual spikes, when a metric runs at 10× or more its usual rate for two readings in a row, like a runaway Durable Object alarm loop. They're macOS notifications, checked every 15 minutes while FlareMeter runs." },
  { q: "How is that different from Cloudflare's budget alerts?", a: "Cloudflare processes billable usage once a day, so its budget alerts arrive the day after you cross the threshold. FlareMeter reads the analytics API every 15 minutes, so it can warn you within about 15 to 30 minutes. Keep Cloudflare's alerts on too: they cover times your Mac is off." },
  { q: "What can the token do?", a: "Only read your account's analytics (Account Analytics · Read). It can't change settings, deploy Workers or see your data. FlareMeter keeps it in your Mac's Keychain and sends it only to api.cloudflare.com." },
  { q: "Does it work with several accounts or Workers?", a: "Yes. If your token can see several accounts, pick one in Settings. You can track one Worker or all Workers on the account." },
  { q: "How current are the numbers?", a: "FlareMeter refreshes every 15 minutes, after your Mac wakes, and whenever you press refresh. Cloudflare's analytics themselves run a few minutes behind." },
  { q: "Is FlareMeter made by Cloudflare?", a: "No. FlareMeter is an independent app and isn't affiliated with or endorsed by Cloudflare, Inc." },
];
