import { faqs } from "@/lib/faqs";
import { site } from "@/lib/site";

/** Schema.org data for search engines: the app (free) and the FAQ. */
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
      isAccessibleForFree: true,
      license: `${site.githubUrl}/blob/HEAD/LICENSE`,
      offers: {
        "@type": "Offer",
        price: "0",
        priceCurrency: "USD",
        url: `${site.url}/#download`,
        availability: "https://schema.org/InStock",
        seller: { "@type": "Organization", name: site.seller.name },
      },
      downloadUrl: `${site.url}${site.downloadUrl}`,
      author: { "@type": "Person", name: site.author.name, url: site.author.url },
      publisher: { "@type": "Organization", name: site.seller.name, url: site.url },
    },
    {
      "@context": "https://schema.org",
      "@type": "Organization",
      name: site.seller.name,
      url: site.url,
      logo: `${site.url}/icon.png`,
      email: site.supportEmail,
      brand: { "@type": "Brand", name: site.name },
      sameAs: [site.author.url, site.githubUrl],
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
