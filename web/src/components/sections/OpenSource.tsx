"use client";

import { motion } from "motion/react";
import { Reveal } from "@/components/ui/animated";
import { site } from "@/lib/site";

const included = [
  "Menu bar meter and panel",
  "Small, medium and large widgets",
  "Early-warning alerts",
  "Workers Free and Paid plans",
  "Automatic updates",
];

export function OpenSource() {
  return (
    <section id="download" className="mx-auto max-w-6xl scroll-mt-24 px-5 py-28">
      <Reveal className="mx-auto max-w-2xl text-center">
        <h2 className="text-4xl font-semibold tracking-tight sm:text-5xl">Free. Open source. Yours.</h2>
        <p className="mt-4 text-lg text-white/55">
          No price, no license key, no account. The code is on GitHub under the {site.license}.
        </p>
      </Reveal>
      <Reveal delay={0.1} className="mx-auto mt-14 max-w-md">
        <div className="relative rounded-[32px] p-px">
          {/* A slowly turning gradient border */}
          <div className="absolute inset-0 overflow-hidden rounded-[32px]">
            <motion.div
              className="absolute left-1/2 top-1/2 aspect-square w-[160%] -translate-x-1/2 -translate-y-1/2 bg-[conic-gradient(from_0deg,transparent_0deg,#ff7a2f_60deg,#ffd27a_100deg,transparent_160deg,transparent_360deg)]"
              animate={{ rotate: 360 }}
              transition={{ duration: 8, repeat: Infinity, ease: "linear" }}
            />
          </div>
          <div className="relative rounded-[31px] bg-[#120d0b] p-9 text-center">
            <img src="/icon.png" alt="" className="mx-auto size-20" />
            <div className="mt-4 text-lg font-semibold">{site.name}</div>
            <div className="mt-2 text-6xl font-semibold tracking-tight">Free</div>
            <div className="mt-1 text-sm text-white/45">signed and notarized by Apple</div>
            <ul className="mx-auto mt-7 max-w-[260px] space-y-2.5 text-left text-[15px] text-white/75">
              {included.map((t) => (
                <li key={t} className="flex gap-2.5">
                  <span className="text-orange-400">✓</span> {t}
                </li>
              ))}
            </ul>
            <motion.a
              href={site.downloadUrl}
              className="mt-8 block rounded-full bg-gradient-to-b from-orange-400 to-orange-600 py-3.5 font-semibold text-white shadow-[0_10px_40px_-10px_rgba(255,106,31,0.8)]"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              Download {site.name}
            </motion.a>
            <a
              href={site.githubUrl}
              target="_blank"
              rel="noopener"
              className="mt-3 block rounded-full border border-white/15 py-3 font-semibold text-white/85 transition hover:bg-white/5"
            >
              View source on GitHub
            </a>
            <p className="mt-6 text-xs leading-relaxed text-white/35">
              Requires {site.minimumMacOS} or later. Updates arrive in the app.
              <br />
              If {site.name} saves you a surprise bill,{" "}
              <a href={site.sponsorUrl} target="_blank" rel="noopener" className="text-orange-300 hover:underline">
                sponsor its development
              </a>
              .
            </p>
          </div>
        </div>
      </Reveal>
    </section>
  );
}
