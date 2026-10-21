"use client";

import { motion, useMotionTemplate, useMotionValue } from "motion/react";
import type { ReactNode } from "react";
import { Reveal } from "@/components/ui/animated";

const features: { title: string; body: string; icon: ReactNode }[] = [
  { title: "Early-warning alerts", body: "A notification when a metric nears or hits its limit, when estimated charges pass your budget, or when usage spikes to 10× its usual rate, like a runaway Durable Object loop. Checked every 15 minutes.", icon: "⚑" },
  { title: "Always in view", body: "Your fullest limit's percentage sits in the menu bar, and turns into a warning cloud past 85%.", icon: "◔" },
  { title: "Free and Paid plans", body: "Daily caps on Workers Free, with the time until the 00:00 UTC reset. Monthly included amounts on Paid, with estimated charges past them.", icon: "⇅" },
  { title: "Widgets that match", body: "Small, medium and large desktop widgets show the same reading as the menu bar, each with a refresh button.", icon: "▦" },
  { title: "Every product you use", body: "Workers, Durable Objects, KV, D1 and Workers AI. Products you don't use stay out of the way.", icon: "✦" },
  { title: "Read-only by design", body: "One permission: Account Analytics · Read. FlareMeter can't change anything on your account.", icon: "⌁" },
];

export function Features() {
  return (
    <section id="features" className="mx-auto max-w-6xl scroll-mt-24 px-5 py-28">
      <Reveal className="mx-auto max-w-2xl text-center">
        <h2 className="text-4xl font-semibold tracking-tight sm:text-5xl">Everything you check the dashboard for.</h2>
        <p className="mt-4 text-lg text-white/55">Without opening the dashboard.</p>
      </Reveal>
      <div className="mt-14 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {features.map((f, i) => (
          <Reveal key={f.title} delay={i * 0.06}>
            <Spotlight>
              <div className="grid size-10 place-items-center rounded-xl bg-gradient-to-b from-orange-400/25 to-orange-600/10 text-lg text-orange-300 ring-1 ring-orange-400/20">
                {f.icon}
              </div>
              <h3 className="mt-5 text-lg font-semibold">{f.title}</h3>
              <p className="mt-2 text-[15px] leading-relaxed text-white/55">{f.body}</p>
            </Spotlight>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

/** A card with a soft light that follows the pointer. */
function Spotlight({ children }: { children: ReactNode }) {
  const x = useMotionValue(-200);
  const y = useMotionValue(-200);
  const background = useMotionTemplate`radial-gradient(320px circle at ${x}px ${y}px, rgba(255,140,60,0.14), transparent 70%)`;
  return (
    <motion.div
      className="group relative h-full overflow-hidden rounded-3xl border border-white/[0.07] bg-white/[0.025] p-7"
      onPointerMove={(e) => {
        const r = e.currentTarget.getBoundingClientRect();
        x.set(e.clientX - r.left);
        y.set(e.clientY - r.top);
      }}
      onPointerLeave={() => {
        x.set(-200);
        y.set(-200);
      }}
      whileHover={{ y: -4 }}
      transition={{ type: "spring", stiffness: 300, damping: 25 }}
    >
      <motion.div aria-hidden className="pointer-events-none absolute inset-0" style={{ background }} />
      <div className="relative">{children}</div>
    </motion.div>
  );
}
