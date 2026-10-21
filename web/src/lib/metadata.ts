import type { Metadata } from "next";
import { guides, guidesIndex } from "@/lib/guides";
import { site } from "@/lib/site";

/** Share cards, by id, with their alt text. app/og/[image]/route.tsx renders each at /og/<id>.png. */
export const shareCards: Record<string, string> = {
  home: "FlareMeter's desktop widget: Cloudflare Workers, Durable Objects, KV, D1 and Workers AI usage against your plan",
  guides: guidesIndex.title,
  ...Object.fromEntries(guides.map((g) => [g.slug, g.title])),
};

/** 1200×630: the size Open Graph and X show without cropping. */
export const shareImageSize = { width: 1200, height: 630 };

export function shareImage(card: string) {
  return { url: `/og/${card}.png`, ...shareImageSize, alt: shareCards[card] };
}

/**
 * A page's title, description and canonical path, repeated in its Open Graph and X tags. A page that sets openGraph or
 * twitter replaces the layout's whole object, so this sets every field. Pages without a card of their own share the
 * home card.
 */
export function pageMetadata({
  title,
  description,
  path,
  type = "website",
  card = "home",
}: {
  title: string;
  description: string;
  path: string;
  type?: "website" | "article";
  card?: string;
}): Metadata {
  const shareTitle = `${title} · ${site.name}`;
  const image = shareImage(card);
  return {
    title,
    description,
    alternates: { canonical: path },
    openGraph: { type, url: path, siteName: site.name, locale: "en_US", title: shareTitle, description, images: [image] },
    twitter: {
      card: "summary_large_image",
      site: site.author.handle,
      creator: site.author.handle,
      title: shareTitle,
      description,
      images: [image],
    },
  };
}
