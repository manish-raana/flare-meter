import type { Metadata } from "next";
import Link from "next/link";
import { Guide, type QA } from "@/components/Guide";
import { guides } from "@/lib/guides";
import { site } from "@/lib/site";

const info = guides.find((g) => g.slug === "monitor-cloudflare-workers-usage")!;

export const metadata: Metadata = {
  title: info.title,
  description: info.description,
  alternates: { canonical: `/guides/${info.slug}` },
  openGraph: { type: "article", title: info.title, description: info.description, url: `/guides/${info.slug}` },
};

const faqs: QA[] = [
  { q: "Where do I see Cloudflare Workers usage in the dashboard?", a: "Open dash.cloudflare.com, choose your account, then Workers & Pages. The overview shows requests across your Workers; each Worker's Metrics tab shows its own. KV, D1 and Durable Objects each show usage on their own pages." },
  { q: "Which API token permission do I need to read Workers usage?", a: "Account → Account Analytics → Read. It's read-only: it can query analytics through the GraphQL Analytics API but can't change anything on the account." },
  { q: "How current is Cloudflare's analytics data?", a: "Usually a few minutes behind real time. Checking every 5 to 15 minutes is plenty, and stays well inside the API's rate limits." },
  { q: "Can I get notified before I hit a Workers limit?", a: "Yes. FlareMeter sends a macOS notification when a metric reaches 80% of its limit (you can change the level), when it hits the limit, and when usage suddenly spikes. Cloudflare's own budget alerts work on usage it processes once a day, so they arrive the day after. You can also build your own check on the GraphQL Analytics API, with a scheduled Worker that compares usage to your plan." },
];

const curl = `curl https://api.cloudflare.com/client/v4/graphql \\
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \\
  -H "Content-Type: application/json" \\
  --data '{"query": "{ viewer { accounts(filter: { accountTag: \\"YOUR_ACCOUNT_ID\\" }) { workersInvocationsAdaptive(limit: 100, filter: { datetime_geq: \\"2026-10-10T00:00:00Z\\", datetime_lt: \\"2026-10-10T23:59:59Z\\" }) { sum { requests errors } dimensions { scriptName } } } } }"}'`;

export default function Page() {
  return (
    <Guide
      info={info}
      faqs={faqs}
      answer={
        <>
          Use the Cloudflare dashboard (Workers &amp; Pages → overview) for a quick look, the <b>GraphQL Analytics API</b> with
          a read-only <b>Account Analytics · Read</b> token for scripts and alerts, or a menu bar app like {site.name} to see
          every product against your plan without opening anything.
        </>
      }
    >
      <h2>1. The Cloudflare dashboard</h2>
      <p>
        <b>Workers &amp; Pages</b> shows requests and errors for your Workers, and each Worker&rsquo;s <b>Metrics</b> tab breaks
        them down. KV namespaces, D1 databases and Durable Objects each have their own usage pages, and{" "}
        <b>Manage Account → Billing</b> shows billable usage on Workers Paid.
      </p>
      <p>
        It&rsquo;s accurate and free, but spread across several pages, and you have to remember to look. That&rsquo;s how
        most people find out about a limit: after they hit it.
      </p>

      <h2>2. The GraphQL Analytics API</h2>
      <p>
        Everything the dashboard shows comes from Cloudflare&rsquo;s GraphQL Analytics API, which you can query yourself.
      </p>
      <h3>Create a read-only token</h3>
      <ol>
        <li>In the dashboard, go to <b>Manage Account → API Tokens</b> (account token) or <b>My Profile → API Tokens</b> (user token).</li>
        <li>Create a custom token with one permission: <b>Account · Account Analytics · Read</b>.</li>
        <li>Copy your <b>Account ID</b> from the account home page.</li>
      </ol>
      <h3>Query today&rsquo;s Worker requests</h3>
      <pre><code>{curl}</code></pre>
      <p>
        <code>sum.requests</code> per <code>scriptName</code> is each Worker&rsquo;s request count in the time window. Use
        today&rsquo;s 00:00 UTC as the start to compare with the Free plan&rsquo;s daily limit, or the 1st of the month for
        Workers Paid.
      </p>
      <h3>The datasets for each product</h3>
      <div className="table-scroll">
      <table>
        <thead>
          <tr><th>What</th><th>Dataset</th><th>Fields</th></tr>
        </thead>
        <tbody>
          <tr><td>Worker requests, errors</td><td><code>workersInvocationsAdaptive</code></td><td><code>sum.requests</code>, <code>sum.errors</code></td></tr>
          <tr><td>Durable Object requests</td><td><code>durableObjectsInvocationsAdaptiveGroups</code></td><td><code>sum.requests</code></td></tr>
          <tr><td>Durable Object rows</td><td><code>durableObjectsPeriodicGroups</code></td><td><code>sum.rowsRead</code>, <code>sum.rowsWritten</code></td></tr>
          <tr><td>Durable Object storage</td><td><code>durableObjectsStorageGroups</code></td><td><code>max.storedBytes</code></td></tr>
          <tr><td>KV operations</td><td><code>kvOperationsAdaptiveGroups</code></td><td><code>sum.requests</code> by <code>dimensions.actionType</code></td></tr>
          <tr><td>D1 rows</td><td><code>d1AnalyticsAdaptiveGroups</code></td><td><code>sum.rowsRead</code>, <code>sum.rowsWritten</code></td></tr>
          <tr><td>Workers AI neurons</td><td><code>aiInferenceAdaptiveGroups</code></td><td><code>sum.totalNeurons</code></td></tr>
        </tbody>
      </table>
      </div>
      <p>
        Some of these field names aren&rsquo;t in Cloudflare&rsquo;s documentation yet and can differ between accounts. An
        introspection query (<code>{"{ __type(name: \"Account\") { fields { name } } }"}</code>) lists what your account
        exposes.
      </p>
      <p>
        From here you can build alerts: a scheduled Worker that runs these queries every 15 minutes and posts to Slack or
        email when a metric passes 80% of its limit. Compare against the numbers in the{" "}
        <Link href="/guides/cloudflare-workers-free-plan-limits">Free limits</Link> and{" "}
        <Link href="/guides/cloudflare-workers-paid-pricing">Paid pricing</Link> guides.
      </p>

      <h2>3. A menu bar meter: {site.name}</h2>
      <p>
        {site.name} runs those queries for you every 15 minutes, for Workers, Durable Objects, KV, D1 and Workers AI, and
        compares each one with your plan. The fullest limit&rsquo;s percentage sits in your Mac&rsquo;s menu bar; click it for
        every metric, the time until the daily reset on Free, or estimated charges on Paid. Desktop widgets show the same
        reading, and notifications warn you when a limit gets close, estimated charges pass your budget, or a metric spikes
        to 10× its usual rate.
      </p>
      <ul>
        <li>Setup takes a minute: it opens Cloudflare&rsquo;s token page with the read-only permission already selected.</li>
        <li>The token stays in your Mac&rsquo;s Keychain and is sent only to Cloudflare. There&rsquo;s no {site.name} server.</li>
        <li>Free and open source (<a href={site.githubUrl}>GitHub</a>).</li>
      </ul>

      <h2>Which should you use?</h2>
      <div className="table-scroll">
      <table>
        <thead>
          <tr><th></th><th>Dashboard</th><th>GraphQL API</th><th>{site.name}</th></tr>
        </thead>
        <tbody>
          <tr><td>Cost</td><td>Free</td><td>Free</td><td>Free</td></tr>
          <tr><td>Setup</td><td>None</td><td>Token + code</td><td>Token, one minute</td></tr>
          <tr><td>All products in one view</td><td>No</td><td>If you build it</td><td>Yes</td></tr>
          <tr><td>Against your plan&rsquo;s limits</td><td>Partly</td><td>If you build it</td><td>Yes</td></tr>
          <tr><td>Always visible</td><td>No</td><td>Alerts only</td><td>Menu bar and widgets</td></tr>
          <tr><td>Alerts</td><td>Budget alerts, next day</td><td>If you build them</td><td>Every 15 minutes, with spike detection</td></tr>
        </tbody>
      </table>
      </div>
    </Guide>
  );
}
