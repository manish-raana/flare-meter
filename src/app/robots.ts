import type { MetadataRoute } from "next";
import { site } from "@/lib/site";

// Written once at build time (static export).
export const dynamic = "force-static";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: "*", allow: "/", disallow: ["/downloads/"] },
    sitemap: `${site.url}/sitemap.xml`,
  };
}
