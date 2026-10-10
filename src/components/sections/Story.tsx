"use client";

import { motion, useMotionValueEvent, useScroll, useSpring, useTransform } from "motion/react";
import { useRef, useState } from "react";
import { MenuBarItem } from "@/components/mock/AppMocks";
import { Ring } from "@/components/ui/animated";
import { formatNumber, tone } from "@/lib/format";

const limit = 5_000_000;
const beats = [
  { at: 0, kicker: "Monday, 9:41", title: "A quiet start.", body: "12% of today's Durable Object row reads. The menu bar stays out of the way." },
  { at: 0.38, kicker: "Monday, 13:05", title: "Your launch post takes off.", body: "Traffic climbs, and so does the number next to the cloud. You see it without opening a dashboard." },
  { at: 0.72, kicker: "Monday, 16:20", title: "You notice before the cap does.", body: "Past 85% the cloud turns into a warning, hours before Workers Free stops serving at the limit." },
];

/** A sticky scene whose usage climbs from 12% to 91% as you scroll. */
export function Story() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start start", "end end"] });
  const raw = useTransform(scrollYProgress, [0.05, 0.9], [0.12, 0.91], { clamp: true });
  const value = useSpring(raw, { stiffness: 90, damping: 22 });
  const color = useTransform(value, tone);
  const glow = useTransform(value, (v) => `radial-gradient(60% 60% at 50% 50%, ${tone(v)}33, transparent 70%)`);
  const shadow = useTransform(color, (c) => `0 0 120px -20px ${c}`);
  const used = useTransform(value, (v) => `${formatNumber(v * limit)} of ${formatNumber(limit)} rows read today`);
  const [beat, setBeat] = useState(0);
  useMotionValueEvent(scrollYProgress, "change", (p) => {
    const i = beats.findLastIndex((b) => p >= b.at);
    setBeat(Math.max(0, i));
  });

  return (
    <section ref={ref} className="relative h-[300vh]">
      <div className="sticky top-0 flex h-screen items-center overflow-hidden">
        <motion.div aria-hidden className="absolute inset-0" style={{ background: glow }} />
        <div className="relative mx-auto grid w-full max-w-6xl items-center gap-12 px-5 md:grid-cols-2">
          <div className="min-h-[220px]">
            <motion.div key={beat} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
              <div className="text-sm font-medium uppercase tracking-[0.18em] text-orange-400">{beats[beat].kicker}</div>
              <h2 className="mt-3 text-4xl font-semibold tracking-tight sm:text-5xl">{beats[beat].title}</h2>
              <p className="mt-4 max-w-md text-lg text-white/60">{beats[beat].body}</p>
            </motion.div>
            <div className="mt-8 flex gap-2">
              {beats.map((_, i) => (
                <div key={i} className="h-1 w-10 overflow-hidden rounded-full bg-white/10">
                  <motion.div className="h-full bg-orange-400" animate={{ width: i <= beat ? "100%" : "0%" }} transition={{ duration: 0.4 }} />
                </div>
              ))}
            </div>
          </div>
          <div className="flex flex-col items-center gap-8">
            <div className="rounded-2xl bg-black/40 px-4 py-2 ring-1 ring-white/10 backdrop-blur">
              <MenuBarItem value={value} active />
            </div>
            <motion.div className="rounded-full p-6" style={{ boxShadow: shadow }}>
              <Ring value={value} size={260} stroke={22} fontSize={64} />
            </motion.div>
            <div className="text-center">
              <div className="text-lg font-semibold">DO rows read</div>
              <motion.div className="tabular-nums text-white/55">{used}</motion.div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
