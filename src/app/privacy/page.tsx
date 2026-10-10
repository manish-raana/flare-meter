import type { Metadata } from "next";
import Link from "next/link";
import { Footer } from "@/components/sections/Footer";
import { site } from "@/lib/site";

export const metadata: Metadata = {
  title: "Privacy",
  description: "FlareMeter collects no data: no server, account, analytics or tracking. Here's what stays on your Mac and what leaves it.",
  alternates: { canonical: "/privacy" },
  openGraph: { url: "/privacy", title: "FlareMeter Privacy" },
};

export default function Privacy() {
  return (
    <>
      <header className="mx-auto flex h-16 max-w-6xl items-center px-5">
        <Link href="/" className="flex items-center gap-2.5 font-semibold tracking-tight">
          <img src="/icon.png" alt="" className="size-7" />
          {site.name}
        </Link>
      </header>
      <main className="mx-auto max-w-2xl px-5 pb-24 pt-12 leading-relaxed text-white/60 [&_b]:text-white/90 [&_code]:text-orange-200 [&_h2]:mb-3 [&_h2]:mt-10 [&_h2]:text-xl [&_h2]:font-semibold [&_h2]:text-white [&_li]:mt-2 [&_ul]:list-disc [&_ul]:pl-5">
        <h1 className="text-5xl font-semibold tracking-tight text-white">Privacy</h1>
        <p className="mt-6 text-lg">
          <b>FlareMeter collects no data.</b> There’s no FlareMeter server, account, analytics or tracking. The app talks
          only to the three services below.
        </p>

        <h2>What stays on your Mac</h2>
        <ul>
          <li>Your Cloudflare API token, kept in your Mac’s Keychain.</li>
          <li>
            Your account ID, chosen Worker and plan, the latest usage reading, and your license key, kept in the app’s
            private container so its widgets can show them.
          </li>
        </ul>

        <h2>What leaves your Mac</h2>
        <ul>
          <li>
            <b>Cloudflare</b> (<code>api.cloudflare.com</code>): your token, to read your account’s usage analytics.
          </li>
          <li>
            <b>Dodo Payments</b> (<code>live.dodopayments.com</code>): when you activate a license, your license key and
            your Mac’s name (so you can tell your Macs apart); about once a day, the key, to check it’s still valid.
          </li>
          <li>
            <b>Updates</b> (<code>flaremeter.pages.dev</code>): the app checks this site’s update list. It sends no
            information about you or your Mac.
          </li>
        </ul>
        <p className="mt-4">Purchases happen on Dodo Payments’ checkout, under its privacy policy; FlareMeter never sees payment details.</p>

        <h2>Removing your data</h2>
        <p>
          Choose <b>Disconnect</b> in FlareMeter’s settings to delete the token, and <b>Deactivate This Mac</b> to remove the
          license, or delete the app. You can also revoke the token any time in the Cloudflare dashboard under API Tokens.
        </p>

        <h2>Contact</h2>
        <p>
          Questions: <a className="text-orange-300 hover:underline" href={`mailto:${site.supportEmail}`}>{site.supportEmail}</a>
        </p>
        <p className="mt-8 text-sm text-white/35">Last updated October 10, 2026.</p>
      </main>
      <Footer />
    </>
  );
}
