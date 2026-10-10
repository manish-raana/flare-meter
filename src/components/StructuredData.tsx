import { faqs } from "@/lib/faqs";
import { site } from "@/lib/site";

/** Schema.org data for search engines: the app (with its price) and the FAQ. */
export function StructuredData() {
  const data = [
    {
      "@context": "https://schema.org",
      "@type": "SoftwareApplication",
      name: site.name,
      description: site.description,
      url: site.url,
      image: `${site.url}/og.png`,
      applicationCategory: "DeveloperApplication",
      operatingSystem: `${site.minimumMacOS} or later`,
      offers: { "@type": "Offer", price: site.price.replace("$", ""), priceCurrency: "USD", url: `${site.url}/#buy` },
      author: { "@type": "Person", name: site.author.name, url: site.author.url },
    },
    {
      "@context": "https://schema.org",
      "@type": "FAQPage",
      mainEntity: faqs.map((f) => ({ "@type": "Question", name: f.q, acceptedAnswer: { "@type": "Answer", text: f.a } })),
    },
  ];
  return (
    <script
      type="application/ld+json"
      // Escaped so text can't close the script tag.
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data).replace(/</g, "\\u003c") }}
    />
  );
}
