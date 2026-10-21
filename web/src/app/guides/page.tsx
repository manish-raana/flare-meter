import type { Metadata } from "next";
import Link from "next/link";
import { Page, formatDate } from "@/components/Page";
import { guides } from "@/lib/guides";

export const metadata: Metadata = {
  title: "Cloudflare Workers guides: limits, pricing and monitoring",
  description: "Plain-English guides to Cloudflare Workers Free limits, Workers Paid pricing, and monitoring your usage.",
  alternates: { canonical: "/guides" },
};

export default function Guides() {
  return (
    <Page
      title="Guides"
      lede="Plain-English answers about Cloudflare Workers limits, pricing and usage, kept up to date."
      crumbs={[{ name: "Guides", path: "/guides" }]}
    >
      <div className="not-prose grid gap-4">
        {guides.map((g) => (
          <Link key={g.slug} href={`/guides/${g.slug}`} className="group rounded-3xl border border-white/[0.08] bg-white/[0.025] p-6 transition hover:border-orange-400/30 hover:bg-white/[0.04]">
            <h2 className="text-xl font-semibold text-white group-hover:text-orange-200">{g.title}</h2>
            <p className="mt-2 text-white/55">{g.description}</p>
            <p className="mt-3 text-sm text-white/35">Updated {formatDate(g.updated)}</p>
          </Link>
        ))}
      </div>
    </Page>
  );
}
