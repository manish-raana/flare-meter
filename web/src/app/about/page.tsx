import type { Metadata } from "next";
import Link from "next/link";
import { Page } from "@/components/Page";
import { site } from "@/lib/site";

export const metadata: Metadata = {
  title: "About",
  description: `Why ${site.name} exists, who makes it, and how it works.`,
  alternates: { canonical: "/about" },
};

export default function About() {
  return (
    <Page
      title={`About ${site.name}`}
      lede="A small Mac app for one job: knowing how close your Cloudflare Workers are to their limits, without opening the dashboard."
      crumbs={[{ name: "About", path: "/about" }]}
    >
      <h2>Why it exists</h2>
      <p>
        Cloudflare&rsquo;s Workers Free plan has daily limits, and Workers Paid bills past monthly included amounts. Checking
        how close you are means opening the dashboard and clicking through Workers, Durable Objects, KV, D1 and Workers AI
        one by one. {site.name} reads the same numbers from Cloudflare&rsquo;s analytics API every 15 minutes and shows the
        fullest one in your menu bar, and sends a notification when a limit gets close or usage suddenly spikes, so you
        notice before it becomes an outage or a bill.
      </p>

      <h2>Who makes it</h2>
      <p>
        {site.name} is built by <a href={site.author.url} target="_blank" rel="noopener me">Manish</a>, a developer who runs
        production apps on Cloudflare Workers, under {site.seller.name}, a {site.seller.type} in {site.seller.country}.
        It&rsquo;s free and open source: the code is on <a href={site.githubUrl}>GitHub</a> under the {site.license}, and
        you can <a href={site.sponsorUrl}>sponsor</a> its development.
      </p>

      <h2>How it&rsquo;s built</h2>
      <ul>
        <li>A native macOS app in Swift and SwiftUI, with WidgetKit widgets. No Electron, no background browser.</li>
        <li>It talks to Cloudflare&rsquo;s GraphQL Analytics API directly from your Mac with a read-only token. There&rsquo;s no {site.name} server.</li>
        <li>Signed and notarized by Apple, updated in place with Sparkle.</li>
      </ul>

      <h2>Get in touch</h2>
      <p>
        Questions, ideas or bugs: <Link href="/contact">contact us</Link> or write to{" "}
        <a href={`mailto:${site.supportEmail}`}>{site.supportEmail}</a>. {site.name} isn&rsquo;t affiliated with Cloudflare, Inc.
      </p>
    </Page>
  );
}
