import Link from "next/link";
import type { ReactNode } from "react";
import { JsonLd } from "@/components/JsonLd";
import { Footer } from "@/components/sections/Footer";
import { site } from "@/lib/site";

export type Crumb = { name: string; path: string };

/** The layout for every page but the home page: a simple header, a readable column, the footer. */
export function Page({ title, lede, updated, crumbs, children, wide = false }: {
  title: string;
  lede?: ReactNode;
  /** "Last updated" date, shown under the title (YYYY-MM-DD). */
  updated?: string;
  crumbs: Crumb[];
  children: ReactNode;
  wide?: boolean;
}) {
  const trail = [{ name: "Home", path: "/" }, ...crumbs];
  return (
    <>
      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "BreadcrumbList",
          itemListElement: trail.map((c, i) => ({ "@type": "ListItem", position: i + 1, name: c.name, item: `${site.url}${c.path === "/" ? "" : c.path}` })),
        }}
      />
      <header className="border-b border-white/[0.06]">
        <nav className="mx-auto flex h-16 max-w-6xl items-center gap-6 px-5">
          <Link href="/" className="flex items-center gap-2.5 font-semibold tracking-tight">
            <img src="/icon.png" alt="" className="size-7" />
            {site.name}
          </Link>
          <div className="ml-auto hidden items-center gap-6 text-sm text-white/60 sm:flex">
            <Link href="/#features" className="hover:text-white">Features</Link>
            <Link href="/guides" className="hover:text-white">Guides</Link>
            <Link href="/contact" className="hover:text-white">Contact</Link>
            <a href={site.githubUrl} target="_blank" rel="noopener" className="hover:text-white">GitHub</a>
          </div>
          <Link href="/#download" className="ml-auto rounded-full bg-white px-4 py-1.5 text-sm font-semibold text-black hover:bg-orange-100 sm:ml-0">
            Download
          </Link>
        </nav>
      </header>
      <main className={`mx-auto px-5 pb-24 pt-10 ${wide ? "max-w-4xl" : "max-w-3xl"}`}>
        <ol className="flex flex-wrap gap-1.5 text-sm text-white/40">
          {trail.map((c, i) => (
            <li key={c.path} className="flex gap-1.5">
              {i > 0 && <span aria-hidden>/</span>}
              {i < trail.length - 1 ? <Link href={c.path} className="hover:text-white">{c.name}</Link> : <span className="text-white/60">{c.name}</span>}
            </li>
          ))}
        </ol>
        <h1 className="mt-6 text-4xl font-semibold tracking-tight text-white sm:text-5xl">{title}</h1>
        {lede && <p className="mt-5 text-lg leading-relaxed text-white/60">{lede}</p>}
        {updated && <p className="mt-3 text-sm text-white/35">Last updated {formatDate(updated)}</p>}
        <div className="prose-flare mt-10">{children}</div>
      </main>
      <Footer />
    </>
  );
}

export function formatDate(iso: string) {
  return new Date(`${iso}T12:00:00Z`).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric", timeZone: "UTC" });
}

/** A short, direct answer at the top of a guide (what answer engines quote). */
export function QuickAnswer({ children }: { children: ReactNode }) {
  return (
    <div className="not-prose rounded-2xl border border-orange-400/20 bg-orange-500/[0.06] p-5 text-[15.5px] leading-relaxed text-white/80">
      <div className="mb-1.5 text-xs font-semibold uppercase tracking-[0.14em] text-orange-300">Quick answer</div>
      {children}
    </div>
  );
}

/** A note pointing to FlareMeter, at the end of guides. */
export function ProductNote({ children }: { children: ReactNode }) {
  return (
    <div className="not-prose mt-12 flex flex-col gap-4 rounded-3xl border border-white/[0.08] bg-white/[0.03] p-6 sm:flex-row sm:items-center">
      <img src="/icon.png" alt="" className="size-14" />
      <div className="flex-1 text-[15px] leading-relaxed text-white/65">{children}</div>
      <Link href="/#download" className="shrink-0 rounded-full bg-gradient-to-b from-orange-400 to-orange-600 px-5 py-2.5 text-center font-semibold text-white">
        Get {site.name} · Free
      </Link>
    </div>
  );
}
