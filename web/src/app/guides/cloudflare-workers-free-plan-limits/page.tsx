import type { Metadata } from "next";
import Link from "next/link";
import { Guide, LimitsTable, type QA } from "@/components/Guide";
import { guides } from "@/lib/guides";

const info = guides.find((g) => g.slug === "cloudflare-workers-free-plan-limits")!;

export const metadata: Metadata = {
  title: info.title,
  description: info.description,
  alternates: { canonical: `/guides/${info.slug}` },
  openGraph: { type: "article", title: info.title, description: info.description, url: `/guides/${info.slug}` },
};

const faqs: QA[] = [
  { q: "Is the Workers Free request limit per Worker or per account?", a: "Per account. The 100,000 requests a day are shared by every Worker on the account, so one busy Worker can use up the allowance for all of them." },
  { q: "When do Cloudflare Workers Free limits reset?", a: "Every day at 00:00 UTC. Usage counts from midnight UTC, not from your local midnight or from your first request." },
  { q: "Will Cloudflare charge me if I go over the free limits?", a: "No. Workers Free never bills you. Past a daily limit, the affected requests or operations fail until the reset. To keep serving past the limits, upgrade to Workers Paid ($5 a month)." },
  { q: "What error do I get when a Worker exceeds the free daily request limit?", a: "Requests to the Worker return Cloudflare error 1027 until 00:00 UTC. For Workers on routes, you can instead choose to let requests bypass the Worker and go to your origin (fail open)." },
  { q: "How much CPU time does a Worker get on the free plan?", a: "10 milliseconds of CPU time per request on Workers Free. Time spent waiting on network requests doesn't count toward it." },
];

export default function Page() {
  return (
    <Guide
      info={info}
      faqs={faqs}
      answer={
        <>
          Workers Free allows <b>100,000 Worker requests per day</b>, shared by every Worker on the account, and resets at{" "}
          <b>00:00 UTC</b>. Durable Objects, KV, D1 and Workers AI have their own daily caps (5 million D1 rows read, 1,000 KV
          writes, 10,000 AI neurons, and more below). Past a cap, requests fail until the reset; you&rsquo;re never charged.
        </>
      }
    >
      <h2>Every daily limit on Workers Free</h2>
      <p>These are the allowances FlareMeter measures against on the Free plan. All are per account, per day.</p>
      <LimitsTable columns={[{ key: "freeDaily", label: "Free, per day" }]} />
      <p>
        Two limits work per request rather than per day: each request gets <b>10 ms of CPU time</b>, and a Worker can make up
        to 50 subrequests per request.
      </p>

      <h2>When the limits reset</h2>
      <p>
        Daily limits reset at <b>00:00 UTC</b>. If you&rsquo;re in India (UTC+5:30) that&rsquo;s 5:30 in the morning; on the US
        West Coast it&rsquo;s 4 or 5 in the afternoon, depending on daylight saving. A traffic spike in your evening can
        exhaust the next UTC day&rsquo;s allowance early.
      </p>

      <h2>What happens when you hit a limit</h2>
      <ul>
        <li>
          <b>Worker requests:</b> requests return error 1027 until the reset. On routes you can set the failure mode to
          &ldquo;fail open&rdquo;, so requests go to your origin without the Worker.
        </li>
        <li><b>KV, D1 and Durable Objects:</b> operations past the cap fail with an error, which your Worker sees as an exception.</li>
        <li><b>Workers AI:</b> inference requests are refused until the neuron allowance resets.</li>
      </ul>
      <p>
        Nothing is billed: the Free plan only stops. That makes it safe for side projects, and risky for anything people rely
        on, because a launch or a crawler can take your app down for the rest of the UTC day.
      </p>

      <h2>The limits people hit first</h2>
      <ol>
        <li><b>KV writes (1,000 a day).</b> The smallest allowance by far. Writing a counter or a session per request runs out within minutes of real traffic.</li>
        <li><b>Worker requests (100,000 a day).</b> About 70 requests a minute averaged over the day, less at your peak.</li>
        <li><b>Durable Object and D1 rows written (100,000 a day).</b> A chatty app that writes on every message gets here fast.</li>
      </ol>

      <h2>How to see how close you are</h2>
      <p>
        The Cloudflare dashboard shows each product&rsquo;s usage on its own page. The{" "}
        <Link href="/guides/monitor-cloudflare-workers-usage">monitoring guide</Link> covers the dashboard, the GraphQL Analytics
        API, and how to watch everything in one place.
      </p>

      <h2>When to move to Workers Paid</h2>
      <p>
        If you&rsquo;re regularly above half of any daily cap, or an outage until midnight UTC would hurt, Workers Paid ($5 a
        month) replaces the daily caps with much larger monthly included amounts and bills past them instead of failing. See{" "}
        <Link href="/guides/cloudflare-workers-paid-pricing">Workers Paid pricing explained</Link>.
      </p>
    </Guide>
  );
}
