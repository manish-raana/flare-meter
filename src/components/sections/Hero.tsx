"use client";

import { motion, useMotionValue, useSpring, useTransform } from "motion/react";
import { LargeWidget, MediumWidget, MenuBar, Panel, SmallWidget } from "@/components/mock/AppMocks";
import { ScaledStage, useCountUp } from "@/components/ui/animated";
import { fraction, sampleMetrics } from "@/lib/sample";
import { site } from "@/lib/site";

const words = ["Know", "your", "Cloudflare", "limits", "before", "you", "hit", "them."];
const ease = [0.16, 1, 0.3, 1] as const;

export function Hero() {
  // Animations start on mount.
  const ready = true;
  const menuValue = useCountUp(fraction(sampleMetrics[0]), ready, 0.9, 1.8);

  // A slight 3D tilt following the pointer.
  const px = useMotionValue(0);
  const py = useMotionValue(0);
  const rotateY = useSpring(useTransform(px, [-0.5, 0.5], [-5, 5]), { stiffness: 120, damping: 20 });
  const rotateX = useSpring(useTransform(py, [-0.5, 0.5], [4, -4]), { stiffness: 120, damping: 20 });

  return (
    <section
      className="relative overflow-hidden pb-24 pt-36"
      onPointerMove={(e) => {
        const r = e.currentTarget.getBoundingClientRect();
        px.set((e.clientX - r.left) / r.width - 0.5);
        py.set((e.clientY - r.top) / r.height - 0.5);
      }}
    >
      <Glow />
      <div className="relative mx-auto max-w-6xl px-5 text-center">
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, ease }}
          className="mx-auto mb-6 inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs text-white/70"
        >
          <span className="size-1.5 animate-pulse rounded-full bg-orange-400" /> A menu bar app and widgets for Workers developers
        </motion.div>
        <h1 className="mx-auto max-w-5xl text-[clamp(2.6rem,7vw,5.4rem)] font-semibold leading-[1.02] tracking-[-0.04em]">
          {words.map((w, i) => (
            <motion.span
              key={i}
              className={`mr-[0.22em] inline-block ${w === "limits" ? "bg-gradient-to-br from-amber-300 via-orange-400 to-orange-600 bg-clip-text text-transparent" : ""}`}
              initial={{ opacity: 0, y: 28, filter: "blur(10px)" }}
              animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
              transition={{ duration: 0.9, delay: 0.08 * i, ease }}
            >
              {w}
            </motion.span>
          )).flatMap((el, i) => (words[i] === "limits" ? [el, <span key="br" className="hidden sm:block" />] : [el]))}
        </h1>
        <motion.p
          className="mx-auto mt-6 max-w-2xl text-lg text-white/60 sm:text-xl"
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.6, ease }}
        >
          FlareMeter puts Workers, Durable Objects, KV, D1 and Workers AI usage in your menu bar and on your desktop,
          measured against your plan. One glance, no dashboard.
        </motion.p>
        <motion.div
          className="mt-9 flex flex-wrap items-center justify-center gap-3"
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.75, ease }}
        >
          <a
            href="#buy"
            className="group relative rounded-full bg-gradient-to-b from-orange-400 to-orange-600 px-6 py-3 font-semibold text-white shadow-[0_10px_40px_-10px_rgba(255,106,31,0.8)] transition hover:brightness-110"
          >
            Buy FlareMeter · {site.price}
          </a>
          <a href="#how" className="rounded-full border border-white/15 px-6 py-3 font-semibold text-white/85 transition hover:bg-white/5">
            See how it works
          </a>
        </motion.div>
        <p className="mt-4 text-sm text-white/40">One-time purchase · {site.minimumMacOS} or later · No account, no tracking</p>
      </div>

      <motion.div
        className="relative mx-auto mt-16 max-w-[1200px] px-5 [perspective:1600px]"
        initial={{ opacity: 0, y: 60 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 1.2, delay: 0.5, ease }}
      >
        <motion.div style={{ rotateX, rotateY, transformStyle: "preserve-3d" }}>
          <ScaledStage width={1160} height={560}>
            <Desktop menuValue={menuValue} ready={ready} />
          </ScaledStage>
        </motion.div>
      </motion.div>
    </section>
  );
}

function Desktop({ menuValue, ready }: { menuValue: ReturnType<typeof useCountUp>; ready: boolean }) {
  return (
    <div className="relative h-[560px] w-[1160px] overflow-hidden rounded-[28px] ring-1 ring-white/10 shadow-[0_60px_160px_-40px_rgba(255,90,20,0.45)]">
      {/* Wallpaper */}
      <div className="absolute inset-0 bg-[radial-gradient(120%_90%_at_20%_0%,#ff9a3c_0%,#e2501d_38%,#5a1a0c_75%,#1a0a07_100%)]" />
      <motion.div
        className="absolute -left-40 top-40 size-[520px] rounded-full bg-amber-300/30 blur-[90px]"
        animate={{ x: [0, 60, 0], y: [0, -30, 0] }}
        transition={{ duration: 14, repeat: Infinity, ease: "easeInOut" }}
      />
      <div className="absolute inset-x-0 top-0">
        <MenuBar value={menuValue} active />
      </div>

      {/* Widgets */}
      <Float delay={0.9} className="absolute left-8 top-14">
        <LargeWidget active={ready} />
      </Float>
      <Float delay={1.05} amplitude={7} className="absolute left-[412px] top-14">
        <SmallWidget active={ready} />
      </Float>
      <Float delay={1.2} amplitude={5} className="absolute left-[412px] top-[242px]">
        <MediumWidget active={ready} />
      </Float>

      {/* The panel dropping from the menu bar item */}
      <motion.div
        className="absolute right-[28px] top-9 origin-top-right"
        initial={{ opacity: 0, y: -14, scale: 0.94 }}
        animate={ready ? { opacity: 1, y: 0, scale: 1 } : {}}
        transition={{ duration: 0.7, delay: 1.5, ease }}
      >
        <Panel active={ready} />
      </motion.div>
    </div>
  );
}

function Float({ children, className, delay, amplitude = 6 }: { children: React.ReactNode; className: string; delay: number; amplitude?: number }) {
  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y: 30, scale: 0.96 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      transition={{ duration: 0.9, delay, ease }}
    >
      <motion.div animate={{ y: [0, -amplitude, 0] }} transition={{ duration: 6 + amplitude / 2, repeat: Infinity, ease: "easeInOut", delay: delay + 1 }}>
        {children}
      </motion.div>
    </motion.div>
  );
}

/** Slow drifting orange light behind the hero. */
function Glow() {
  return (
    <div aria-hidden className="pointer-events-none absolute inset-0">
      <div className="absolute inset-0 bg-[linear-gradient(to_right,rgba(255,255,255,0.04)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.04)_1px,transparent_1px)] bg-[size:56px_56px] [mask-image:radial-gradient(70%_60%_at_50%_30%,black,transparent)]" />
      <motion.div
        className="absolute left-1/2 top-[-260px] size-[900px] -translate-x-1/2 rounded-full bg-orange-600/25 blur-[140px]"
        animate={{ scale: [1, 1.12, 1], opacity: [0.7, 1, 0.7] }}
        transition={{ duration: 10, repeat: Infinity, ease: "easeInOut" }}
      />
      <motion.div
        className="absolute right-[-200px] top-[300px] size-[520px] rounded-full bg-amber-400/15 blur-[120px]"
        animate={{ x: [0, -80, 0], y: [0, 40, 0] }}
        transition={{ duration: 16, repeat: Infinity, ease: "easeInOut" }}
      />
    </div>
  );
}
