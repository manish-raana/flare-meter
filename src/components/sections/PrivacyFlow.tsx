"use client";

import { motion } from "motion/react";
import { Reveal } from "@/components/ui/animated";
import { CloudIcon } from "@/components/ui/icons";

/** Your Mac talks to Cloudflare directly; there's no FlareMeter server in between. */
export function PrivacyFlow() {
  return (
    <section className="mx-auto max-w-6xl px-5 py-28">
      <div className="grid items-center gap-14 md:grid-cols-2">
        <Reveal>
          <h2 className="text-4xl font-semibold tracking-tight sm:text-5xl">No server in the middle.</h2>
          <p className="mt-5 text-lg leading-relaxed text-white/60">
            FlareMeter talks to Cloudflare’s API straight from your Mac, with a token that can only read analytics. Your
            token stays in your Keychain. There’s no FlareMeter account, no analytics, no tracking.
          </p>
          <ul className="mt-6 space-y-2 text-white/70">
            {["Read-only Account Analytics token", "Stored in your Mac's Keychain", "Sent only to api.cloudflare.com"].map((t) => (
              <li key={t} className="flex items-center gap-2">
                <span className="text-emerald-400">✓</span> {t}
              </li>
            ))}
          </ul>
        </Reveal>
        <Reveal delay={0.1}>
          <div className="relative rounded-3xl border border-white/[0.07] bg-white/[0.025] p-8">
            <div className="flex items-center justify-between">
              <Node label="Your Mac" sub="FlareMeter" icon={<img src="/icon.png" alt="" className="size-9" />} />
              <div className="relative mx-4 h-px flex-1 bg-gradient-to-r from-orange-400/30 via-orange-400/60 to-orange-400/30">
                {[0, 1, 2].map((i) => (
                  <motion.span
                    key={i}
                    className="absolute -top-[3px] size-[7px] rounded-full bg-orange-300 shadow-[0_0_12px_#ffb15c]"
                    animate={{ left: ["0%", "100%"], opacity: [0, 1, 1, 0] }}
                    transition={{ duration: 2.4, repeat: Infinity, delay: i * 0.8, ease: "easeInOut" }}
                  />
                ))}
              </div>
              <Node label="api.cloudflare.com" sub="Analytics, read-only" icon={<CloudIcon className="size-9 text-orange-400" />} />
            </div>
            <div className="mt-8 flex items-center justify-center gap-3 rounded-2xl border border-dashed border-white/10 py-4 text-sm text-white/35">
              <span className="line-through decoration-white/30">FlareMeter servers</span>
              <span className="rounded-full bg-white/5 px-2 py-0.5 text-xs">none</span>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

function Node({ label, sub, icon }: { label: string; sub: string; icon: React.ReactNode }) {
  return (
    <div className="flex w-32 flex-col items-center gap-2 text-center">
      <div className="grid size-16 place-items-center rounded-2xl bg-black/40 ring-1 ring-white/10">{icon}</div>
      <div className="text-sm font-semibold">{label}</div>
      <div className="text-xs text-white/45">{sub}</div>
    </div>
  );
}
