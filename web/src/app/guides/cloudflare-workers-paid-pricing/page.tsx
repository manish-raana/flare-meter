import type { Metadata } from "next";
import Link from "next/link";
import { Guide, LimitsTable, type QA } from "@/components/Guide";
import { guides } from "@/lib/guides";

const info = guides.find((g) => g.slug === "cloudflare-workers-paid-pricing")!;

export const metadata: Metadata = {
  title: info.title,
  description: info.description,
  alternates: { canonical: `/guides/${info.slug}` },
  openGraph: { type: "article", title: info.title, description: info.description, url: `/guides/${info.slug}` },
};

const faqs: QA[] = [
  { q: "How much does Cloudflare Workers Paid cost?", a: "A minimum of $5 per month per account. That includes 10 million Worker requests and 30 million CPU milliseconds a month, plus included amounts for Durable Objects, KV and D1. Usage past them is billed per million." },
  { q: "Does Workers Paid have daily limits?", a: "No daily caps on requests, KV, D1 or Durable Objects: the included amounts are monthly, and usage past them is billed instead of failing. Workers AI keeps its 10,000 free neurons a day, then bills per 1,000 neurons." },
  { q: "When does the Workers Paid usage period reset?", a: "Included amounts count per billing month. FlareMeter measures from the start of the calendar month in UTC, which matches most accounts' billing cycles; your invoice is the authority." },
  { q: "How can I avoid a surprise Cloudflare Workers bill?", a: "Watch usage against the included amounts during the month rather than waiting for the invoice: in the dashboard, with the GraphQL Analytics API, or with a menu bar meter like FlareMeter that shows estimated charges as they build up." },
];

export default function Page() {
  return (
    <Guide
      info={info}
      faqs={faqs}
      answer={
        <>
          Workers Paid costs <b>$5 a month</b> per account and includes <b>10 million requests</b> and 30 million CPU
          milliseconds, plus monthly amounts for Durable Objects, KV and D1. Past those you pay per use, for example{" "}
          <b>$0.30 per extra million requests</b> and <b>$5 per extra million KV writes</b>. Nothing stops at a limit; it bills.
        </>
      }
    >
      <h2>What&rsquo;s included, and what it costs past that</h2>
      <LimitsTable columns={[{ key: "paidIncluded", label: "Included per month" }, { key: "paidOverage", label: "Past included" }]} />
      <p>
        CPU time is billed too: 30 million CPU milliseconds a month are included, then $0.02 per additional million. Most
        I/O-bound Workers stay well inside it; heavy computation (image work, crypto, large JSON) is where it shows up.
      </p>

      <h2>Worked examples</h2>
      <h3>A busy API: 25 million requests in a month</h3>
      <p>
        15 million requests over the included 10 million × $0.30 per million = <b>$4.50</b>, so the month costs{" "}
        <b>$9.50</b> with the $5 base, if everything else stays inside its included amount.
      </p>
      <h3>A KV-heavy app: 3 million KV writes</h3>
      <p>
        2 million writes over the included 1 million × $5.00 per million = <b>$10</b>, so <b>$15</b> for the month. KV writes
        are the most expensive operation per million, so writing on every request adds up quickly.
      </p>
      <h3>A Durable Objects chat app: 120 million rows written</h3>
      <p>
        70 million rows over the included 50 million × $1.00 per million = <b>$70</b>. Batching writes, or writing on a timer
        instead of per message, is usually the biggest saving.
      </p>

      <h2>Where Workers Paid bills come from</h2>
      <ul>
        <li><b>Write-heavy storage:</b> KV writes and Durable Object / D1 rows written cost the most per million.</li>
        <li><b>Bots and crawlers:</b> unprotected endpoints can multiply requests overnight.</li>
        <li><b>Retries and loops:</b> a client retrying on error, or a Worker calling itself, turns one request into thousands.</li>
      </ul>

      <h2>Keeping an eye on it during the month</h2>
      <p>
        Cloudflare bills at the end of the cycle, so the useful moment to notice is mid-month. The{" "}
        <Link href="/guides/monitor-cloudflare-workers-usage">monitoring guide</Link> shows how to pull month-to-date usage,
        and how FlareMeter turns it into an estimated charge you can see at a glance.
      </p>

      <h2>Free or Paid?</h2>
      <p>
        If you&rsquo;re still deciding, the <Link href="/guides/cloudflare-workers-free-plan-limits">Workers Free limits</Link>{" "}
        guide lists the daily caps and what happens when you hit them.
      </p>
    </Guide>
  );
}
