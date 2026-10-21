import { JsonLd } from "@/components/JsonLd";
import { Page } from "@/components/Page";
import { pageMetadata } from "@/lib/metadata";
import { site } from "@/lib/site";

export const metadata = pageMetadata({
  title: "Contact",
  description: `Questions, bugs or ideas about ${site.name}? Email ${site.supportEmail} or open an issue on GitHub.`,
  path: "/contact",
});

export default function Contact() {
  return (
    <Page title="Contact" crumbs={[{ name: "Contact", path: "/contact" }]}>
      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "ContactPage",
          url: `${site.url}/contact`,
          mainEntity: { "@type": "Organization", name: site.seller.name, url: site.url, email: site.supportEmail },
        }}
      />
      <p>
        Questions, a bug or an idea? Email{" "}
        <a href={`mailto:${site.supportEmail}?subject=${encodeURIComponent(site.name)}`}>{site.supportEmail}</a>. You&rsquo;ll
        hear back from the person who makes {site.name}, usually {site.responseTime}.
      </p>
      <p>
        {site.name} is open source, so you can also <a href={`${site.githubUrl}/issues`}>open an issue</a> or send a pull
        request on <a href={site.githubUrl}>GitHub</a>.
      </p>
    </Page>
  );
}
