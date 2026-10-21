import Link from "next/link";
import { Reveal } from "@/components/ui/animated";
import { guides } from "@/lib/guides";

/** Links to the guides from the home page. */
export function GuidesTeaser() {
  return (
    <section className="mx-auto max-w-6xl px-5 py-24">
      <Reveal className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">Know the limits</h2>
          <p className="mt-3 text-white/55">Plain-English guides to Cloudflare Workers limits and pricing.</p>
        </div>
        <Link href="/guides" className="text-sm text-orange-300 hover:underline">All guides →</Link>
      </Reveal>
      <div className="mt-10 grid gap-4 md:grid-cols-3">
        {guides.map((g, i) => (
          <Reveal key={g.slug} delay={i * 0.06}>
            <Link href={`/guides/${g.slug}`} className="group block h-full rounded-3xl border border-white/[0.07] bg-white/[0.025] p-6 transition hover:border-orange-400/30">
              <h3 className="text-lg font-semibold group-hover:text-orange-200">{g.title}</h3>
              <p className="mt-2 text-[15px] leading-relaxed text-white/55">{g.description}</p>
            </Link>
          </Reveal>
        ))}
      </div>
    </section>
  );
}
