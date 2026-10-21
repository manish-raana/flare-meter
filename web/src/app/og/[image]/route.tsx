import { guides, guidesIndex } from "@/lib/guides";
import { shareCards } from "@/lib/metadata";
import { homeCard, pageCard } from "@/lib/og";

// Rendered at build time to out/og/<id>.png, so the files keep their extension and Cloudflare serves them as PNGs.
export const dynamic = "force-static";
export const dynamicParams = false;

export function generateStaticParams() {
  return Object.keys(shareCards).map((card) => ({ image: `${card}.png` }));
}

export async function GET(_request: Request, { params }: RouteContext<"/og/[image]">) {
  const card = (await params).image.replace(/\.png$/, "");
  if (card === "home") return homeCard();
  if (card === "guides") return pageCard({ eyebrow: "Guides", ...guidesIndex, path: "/guides" });
  const guide = guides.find((g) => g.slug === card)!;
  return pageCard({ eyebrow: "Guide", title: guide.title, description: guide.description, path: `/guides/${guide.slug}` });
}
