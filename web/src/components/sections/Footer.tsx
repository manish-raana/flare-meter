import Link from "next/link";
import { site } from "@/lib/site";

type FooterLink = { label: string; href: string; external?: boolean };

const columns: { title: string; links: FooterLink[] }[] = [
  { title: "Product", links: [
    { label: "Features", href: "/#features" },
    { label: "Download", href: site.downloadUrl },
    { label: "GitHub", href: site.githubUrl, external: true },
    { label: "Sponsor", href: site.sponsorUrl, external: true },
    { label: "FAQ", href: "/#faq" },
  ] },
  { title: "Resources", links: [
    { label: "Guides", href: "/guides" },
    { label: "Workers Free limits", href: "/guides/cloudflare-workers-free-plan-limits" },
    { label: "Workers Paid pricing", href: "/guides/cloudflare-workers-paid-pricing" },
    { label: "Monitor Workers usage", href: "/guides/monitor-cloudflare-workers-usage" },
  ] },
  { title: "Company", links: [
    { label: "About", href: "/about" },
    { label: "Contact", href: "/contact" },
    { label: "Terms", href: "/terms" },
    { label: "Privacy", href: "/privacy" },
  ] },
];

export function Footer() {
  return (
    <footer className="border-t border-white/[0.06]">
      <div className="mx-auto grid max-w-6xl gap-10 px-5 py-14 sm:grid-cols-2 lg:grid-cols-[1.4fr_repeat(3,1fr)_1.3fr]">
        <div className="space-y-3 text-sm text-white/45">
          <Link href="/" className="flex items-center gap-2 font-semibold text-white/80">
            <img src="/icon.png" alt="" className="size-6" /> {site.name}
          </Link>
          <p>Cloudflare Workers usage in your Mac&rsquo;s menu bar and on your desktop. Free and open source.</p>
          <p>
            <a href={`mailto:${site.supportEmail}`} className="hover:text-white">{site.supportEmail}</a>
          </p>
          <a
            href={site.coffeeUrl}
            target="_blank"
            rel="noopener"
            className="inline-flex items-center gap-2 rounded-full bg-[#FFDD00] px-4 py-2 font-semibold text-black transition hover:brightness-95"
          >
            <span aria-hidden>☕</span> Buy me a coffee
          </a>
        </div>
        {columns.map((c) => (
          <div key={c.title}>
            <div className="text-sm font-semibold text-white/80">{c.title}</div>
            <ul className="mt-3 space-y-2 text-sm text-white/45">
              {c.links.map((l) => (
                <li key={l.href}>
                  {l.external ? (
                    <a href={l.href} target="_blank" rel="noopener" className="hover:text-white">{l.label}</a>
                  ) : (
                    <Link href={l.href} className="hover:text-white">{l.label}</Link>
                  )}
                </li>
              ))}
            </ul>
          </div>
        ))}
        <div>
          <div className="text-sm font-semibold text-white/80">More from us</div>
          <ul className="mt-3 space-y-3 text-sm">
            {site.moreTools.map((t) => (
              <li key={t.url}>
                <a href={t.url} target="_blank" rel="noopener" className="group block">
                  <span className="text-white/70 group-hover:text-white">{t.name}</span>
                  <span className="block text-white/40">{t.description}</span>
                </a>
              </li>
            ))}
          </ul>
        </div>
      </div>
      <div className="border-t border-white/[0.06]">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center gap-x-6 gap-y-2 px-5 py-6 text-sm text-white/35">
          <span>
            © 2026 {site.author.name}. Open source under the{" "}
            <a href={`${site.githubUrl}/blob/HEAD/LICENSE`} target="_blank" rel="noopener" className="hover:text-white">{site.license}</a>.{" "}
            {site.name} is not affiliated with or endorsed by Cloudflare, Inc.
          </span>
          <span className="sm:ml-auto">
            Made with <span aria-label="love">❤️</span> by{" "}
            <a href={site.author.url} target="_blank" rel="noopener me" className="text-white/70 hover:text-orange-300">
              Manish
            </a>
          </span>
        </div>
      </div>
    </footer>
  );
}
