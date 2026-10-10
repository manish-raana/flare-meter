import { site } from "./site";

/** Shown in the FAQ section and given to search engines as FAQPage data. */
export const faqs = [
  { q: "Which Cloudflare plans does it support?", a: "Workers Free (daily limits, reset at 00:00 UTC) and Workers Paid (monthly included amounts, with estimated charges past them). Pick yours in Settings." },
  { q: "What can the token do?", a: "Only read your account's analytics (Account Analytics · Read). It can't change settings, deploy Workers or see your data. FlareMeter keeps it in your Mac's Keychain and sends it only to api.cloudflare.com." },
  { q: "Does it work with several accounts or Workers?", a: "Yes. If your token can see several accounts, pick one in Settings. You can track one Worker or all Workers on the account." },
  { q: "How many Macs can I use it on?", a: `One license activates on up to ${site.macsPerLicense} Macs. To move it, choose Deactivate This Mac in Settings, then activate on the new one.` },
  { q: "How current are the numbers?", a: "FlareMeter refreshes every 15 minutes, after your Mac wakes, and whenever you press refresh. Cloudflare's analytics themselves run a few minutes behind." },
  { q: "Is FlareMeter made by Cloudflare?", a: "No. FlareMeter is an independent app and isn't affiliated with or endorsed by Cloudflare, Inc." },
];
