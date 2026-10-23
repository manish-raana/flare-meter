// The site is static files (out/). This Worker only sees what wrangler.jsonc routes to it first: the DMG downloads,
// which it counts (FlareMeter.dmg) and sends to GitHub Releases when the DMG isn't among the static files, and
// /api/downloads, which reads the count for the landing page. Every other path is answered by the static files (and
// their 404 page) without running it.
import { DurableObject } from "cloudflare:workers";
import { releaseURL } from "./downloads";

interface Env {
  ASSETS: Fetcher;
  DOWNLOADS: DurableObjectNamespace<DownloadCounter>;
}

/** The download total, in one Durable Object. Nothing about who downloaded is stored. */
export class DownloadCounter extends DurableObject<Env> {
  async add(): Promise<void> {
    const count = (await this.ctx.storage.get<number>("count")) ?? 0;
    await this.ctx.storage.put("count", count + 1);
  }

  async total(): Promise<number> {
    return (await this.ctx.storage.get<number>("count")) ?? 0;
  }
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const counter = env.DOWNLOADS.get(env.DOWNLOADS.idFromName("FlareMeter.dmg"));

    if (url.pathname === "/api/downloads") {
      // Cached at the edge for 5 minutes, so page views don't each wake the Durable Object.
      const cached = await caches.default.match(request);
      if (cached) return cached;
      const response = Response.json(
        { downloads: await counter.total() },
        { headers: { "Cache-Control": "public, max-age=300" } },
      );
      ctx.waitUntil(caches.default.put(request, response.clone()));
      return response;
    }

    if (url.pathname === "/FlareMeter.dmg" && isNewDownload(request)) ctx.waitUntil(counter.add());
    const asset = await env.ASSETS.fetch(request);
    if (asset.status !== 404) return asset;
    const release = releaseURL(url.pathname);
    return release ? Response.redirect(release, 302) : asset;
  },
} satisfies ExportedHandler<Env>;

/** A person starting a download: a GET from the first byte (not a resumed range), and not a crawler or link preview. */
function isNewDownload(request: Request) {
  if (request.method !== "GET") return false;
  const range = request.headers.get("Range");
  if (range && !range.startsWith("bytes=0-")) return false;
  const agent = request.headers.get("User-Agent") ?? "";
  return !/bot|crawl|spider|slurp|preview|facebookexternalhit|whatsapp|curl|wget|python|headless/i.test(agent);
}
