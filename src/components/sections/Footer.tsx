import Link from "next/link";
import { site } from "@/lib/site";

export function Footer() {
  return (
    <footer className="border-t border-white/[0.06]">
      <div className="mx-auto flex max-w-6xl flex-wrap items-center gap-x-6 gap-y-3 px-5 py-10 text-sm text-white/40">
        <span className="flex items-center gap-2 font-medium text-white/70">
          <img src="/icon.png" alt="" className="size-5" /> {site.name}
        </span>
        <span>© 2026 Manish Rana. Not affiliated with or endorsed by Cloudflare, Inc.</span>
        <span>
          Made with <span aria-label="love">❤️</span> by{" "}
          <a href={site.author.url} target="_blank" rel="noopener me" className="text-white/70 hover:text-orange-300">
            Manish
          </a>
        </span>
        <span className="ml-auto flex gap-5">
          <Link href="/privacy" className="hover:text-white">Privacy</Link>
          <a href={`mailto:${site.supportEmail}`} className="hover:text-white">Support</a>
        </span>
      </div>
    </footer>
  );
}
