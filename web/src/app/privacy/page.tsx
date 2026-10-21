import { Page } from "@/components/Page";
import { pageMetadata } from "@/lib/metadata";
import { site } from "@/lib/site";

export const metadata = pageMetadata({
  title: "Privacy",
  description: `${site.name} has no accounts, analytics or tracking. Your Cloudflare token stays on your Mac. Here's every network call the app makes.`,
  path: "/privacy",
});

const mail = <a href={`mailto:${site.supportEmail}`}>{site.supportEmail}</a>;

export default function Privacy() {
  return (
    <Page title="Privacy" updated="2026-10-21" crumbs={[{ name: "Privacy", path: "/privacy" }]}>
      <p>
        <b>Short version:</b> your Cloudflare token and usage stay on your Mac. There are no {site.name} accounts, no
        analytics, and no {site.name} server. The <a href={site.githubUrl}>source code</a> is public, so you can check.
      </p>

      <h2>What {site.name} keeps on your Mac</h2>
      <p>
        Your Cloudflare API token (in your Keychain), your account ID, chosen Worker and plan, the latest usage reading, and
        your alert settings. They stay in the app&rsquo;s private storage so its widgets can show them. We never see them.
      </p>

      <h2>The only network calls</h2>
      <ul>
        <li>
          <b>Cloudflare</b> (<code>api.cloudflare.com</code>): your token, to read your account&rsquo;s usage analytics every
          15 minutes. This is the app&rsquo;s whole job.
        </li>
        <li>
          <b>Update check</b> (<code>{site.url.replace("https://", "")}</code>): about once a day. Like any web request, it
          shows the server your IP address and app version. Nothing else is sent.
        </li>
      </ul>

      <h2>Alerts</h2>
      <p>
        Alerts are local macOS notifications. {site.name} decides when to show one on your Mac; nothing about your usage is
        sent anywhere to do it.
      </p>

      <h2>Sponsoring</h2>
      <p>
        If you sponsor {site.name}, that happens on GitHub, under{" "}
        <a href="https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement" rel="noopener">
          GitHub&rsquo;s privacy statement
        </a>
        . The app doesn&rsquo;t know whether you sponsor.
      </p>

      <h2>This website</h2>
      <p>A static site with no cookies, analytics or tracking scripts.</p>

      <h2>Contact</h2>
      <p>
        Questions, or want us to delete emails you sent us? Write to {mail}. {site.name} is made by {site.seller.name}.
      </p>
    </Page>
  );
}
