import type { Metadata } from "next";
import Link from "next/link";
import { Page } from "@/components/Page";
import { site } from "@/lib/site";

export const metadata: Metadata = {
  title: "Terms",
  description: `The terms for ${site.name}: free, open-source software under the ${site.license}, provided as is.`,
  alternates: { canonical: "/terms" },
};

const mail = <a href={`mailto:${site.supportEmail}`}>{site.supportEmail}</a>;

export default function Terms() {
  return (
    <Page title="Terms of Use" updated="2026-10-21" crumbs={[{ name: "Terms", path: "/terms" }]}>
      <p>
        By using {site.name} or this website you agree to these terms. {site.name} is made by {site.seller.name}
        (&ldquo;we&rdquo;).
      </p>

      <h2>Free and open source</h2>
      <ul>
        <li>{site.name} is free. There&rsquo;s no purchase, subscription, license key or account.</li>
        <li>
          Its source code is published on <a href={site.githubUrl}>GitHub</a> under the{" "}
          <a href={`${site.githubUrl}/blob/HEAD/LICENSE`}>GNU Affero General Public License v3.0</a>. That license, not
          these terms, sets what you may do with the code: use, study, change and share it, on the license&rsquo;s
          conditions.
        </li>
        <li>
          The signed and notarized app downloads from <Link href="/">{site.url.replace("https://", "")}</Link> and updates
          itself.
        </li>
        <li>
          <a href={site.sponsorUrl}>Sponsoring</a> is voluntary and happens on GitHub. It doesn&rsquo;t buy a license,
          features or support terms.
        </li>
      </ul>

      <h2>Your Cloudflare account</h2>
      <p>
        {site.name} reads usage with a read-only API token you create, and changes nothing on your account. The figures come
        from Cloudflare&rsquo;s analytics and its published prices, so treat estimated charges as estimates: your Cloudflare
        dashboard and invoices are the authority. Alerts depend on your Mac being on and {site.name} running, so they
        don&rsquo;t replace Cloudflare&rsquo;s own billing alerts. {site.name} isn&rsquo;t affiliated with or endorsed by
        Cloudflare, Inc.
      </p>

      <h2>No warranty</h2>
      <p>
        {site.name} is provided &ldquo;as is&rdquo;, without warranties, as the {site.license} also states. To the extent
        the law allows, we aren&rsquo;t liable for any losses or Cloudflare charges, including ones an alert didn&rsquo;t
        catch. Your rights as a consumer under local law aren&rsquo;t affected.
      </p>

      <h2>Changes</h2>
      <p>We may update these terms. The date at the top shows the last change.</p>

      <h2>Contact</h2>
      <p>{mail}</p>
    </Page>
  );
}
