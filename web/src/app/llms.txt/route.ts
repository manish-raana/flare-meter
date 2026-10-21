import { llmsTxt } from "@/lib/llms";

// Written once at build time (static export).
export const dynamic = "force-static";

export function GET() {
  return new Response(llmsTxt(), { headers: { "Content-Type": "text/plain; charset=utf-8" } });
}
