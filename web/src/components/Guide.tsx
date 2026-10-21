import Link from "next/link";
import type { ReactNode } from "react";
import { JsonLd } from "@/components/JsonLd";
import { Page, ProductNote, QuickAnswer } from "@/components/Page";
import { guides, type GuideInfo } from "@/lib/guides";
import { asOf, limits, sources, type Limit } from "@/lib/limits";
import { site } from "@/lib/site";

export type QA = { q: string; a: string };

/** A guide: quick answer, body, FAQ, sources, related guides, and Article + FAQPage data for search engines. */
export function Guide({ info, answer, faqs, children }: { info: GuideInfo; answer: ReactNode; faqs: QA[]; children: ReactNode }) {
  const path = `/guides/${info.slug}`;
  return (
    <Page title={info.title} lede={info.description} updated={info.updated} crumbs={[{ name: "Guides", path: "/guides" }, { name: info.title, path }]}>
      <JsonLd
        data={[
          {
            "@context": "https://schema.org",
            "@type": "TechArticle",
            headline: info.title,
            description: info.description,
            url: `${site.url}${path}`,
            dateModified: info.updated,
            datePublished: info.updated,
            author: { "@type": "Person", name: site.author.name, url: site.author.url },
            publisher: { "@type": "Organization", name: site.seller.name, url: site.url, logo: `${site.url}/icon.png` },
            image: `${site.url}/og.png`,
          },
          {
            "@context": "https://schema.org",
            "@type": "FAQPage",
            mainEntity: faqs.map((f) => ({ "@type": "Question", name: f.q, acceptedAnswer: { "@type": "Answer", text: f.a } })),
          },
        ]}
      />
      <QuickAnswer>{answer}</QuickAnswer>
      {children}
      <h2>Frequently asked questions</h2>
      {faqs.map((f) => (
        <div key={f.q}>
          <h3>{f.q}</h3>
          <p>{f.a}</p>
        </div>
      ))}
      <h2>Sources</h2>
      <p className="text-sm">
        Figures as of {asOf}, from Cloudflare&rsquo;s documentation. Cloudflare changes pricing from time to time, so check the
        current pages before relying on them:
      </p>
      <ul className="text-sm">
        {sources.map((s) => (
          <li key={s.url}><a href={s.url} rel="noopener">{s.label}</a></li>
        ))}
      </ul>
      <ProductNote>
        <b>Skip the math.</b> {site.name} puts these numbers in your Mac&rsquo;s menu bar: your fullest limit as a percentage,
        every product against your plan, refreshed every 15 minutes.
      </ProductNote>
      <h2>More guides</h2>
      <ul>
        {guides.filter((g) => g.slug !== info.slug).map((g) => (
          <li key={g.slug}><Link href={`/guides/${g.slug}`}>{g.title}</Link></li>
        ))}
      </ul>
    </Page>
  );
}

/** The limits table, with the columns a guide needs. */
export function LimitsTable({ columns }: { columns: { key: keyof Limit; label: string }[] }) {
  return (
    <div className="table-scroll">
    <table>
      <thead>
        <tr>
          <th>Product</th>
          <th>Metric</th>
          {columns.map((c) => <th key={c.key}>{c.label}</th>)}
        </tr>
      </thead>
      <tbody>
        {limits.map((l) => (
          <tr key={`${l.product}${l.metric}`}>
            <td>{l.product}</td>
            <td>{l.metric}</td>
            {columns.map((c) => <td key={c.key}>{l[c.key] ?? "—"}</td>)}
          </tr>
        ))}
      </tbody>
    </table>
      </div>
  );
}
