import type { MetadataRoute } from "next";
import { site } from "@/lib/site";

// Written once at build time (static export).
export const dynamic = "force-static";

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: site.url, changeFrequency: "monthly", priority: 1 },
    { url: `${site.url}/privacy`, changeFrequency: "yearly", priority: 0.3 },
  ];
}
