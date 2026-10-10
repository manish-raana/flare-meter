"use client";

import { motion } from "motion/react";
import { useEffect, useState } from "react";
import { Reveal, useSeen } from "@/components/ui/animated";

const token = "cfat_7Kq2mN9xR4vB8wLp3sT6yH1j";

export function Setup() {
  const [ref, seen] = useSeen<HTMLDivElement>();
  return (
    <section id="how" className="mx-auto max-w-6xl scroll-mt-24 px-5 py-28">
      <Reveal className="mx-auto max-w-2xl text-center">
        <h2 className="text-4xl font-semibold tracking-tight sm:text-5xl">Set up in under a minute.</h2>
        <p className="mt-4 text-lg text-white/55">No account to create. No agent to install. One read-only token.</p>
      </Reveal>
      <div ref={ref} className="relative mt-16 grid gap-6 md:grid-cols-3">
        <motion.div
          aria-hidden
          className="absolute left-[16.7%] right-[16.7%] top-[56px] hidden h-px origin-left bg-gradient-to-r from-orange-500/0 via-orange-400/60 to-orange-500/0 md:block"
          initial={{ scaleX: 0 }}
          animate={seen ? { scaleX: 1 } : {}}
          transition={{ duration: 1.4, ease: [0.16, 1, 0.3, 1] }}
        />
        <Step n={1} seen={seen} title="Create a token" body="FlareMeter opens Cloudflare's token page with the one permission it needs already selected.">
          <motion.div
            className="mx-auto w-fit rounded-lg bg-gradient-to-b from-orange-400 to-orange-600 px-4 py-2 text-sm font-semibold"
            animate={seen ? { scale: [1, 1.06, 1] } : {}}
            transition={{ duration: 1.6, repeat: Infinity, repeatDelay: 1.2, delay: 1 }}
          >
            Create Token…
          </motion.div>
        </Step>
        <Step n={2} seen={seen} title="Paste it" body="Your account and Workers are found from the token. Pick your plan, and you're done.">
          <Typing active={seen} />
        </Step>
        <Step n={3} seen={seen} title="Add the widgets" body="Right-click the desktop → Edit Widgets → FlareMeter. They show the same reading as the menu bar.">
          <div className="flex justify-center gap-2">
            {[48, 64, 40].map((w, i) => (
              <motion.div
                key={i}
                className="h-12 rounded-lg bg-white/10 ring-1 ring-white/10"
                style={{ width: w }}
                initial={{ opacity: 0, y: 12 }}
                animate={seen ? { opacity: 1, y: 0 } : {}}
                transition={{ delay: 1.2 + i * 0.15 }}
              />
            ))}
          </div>
        </Step>
      </div>
    </section>
  );
}

function Step({ n, title, body, seen, children }: { n: number; title: string; body: string; seen: boolean; children: React.ReactNode }) {
  return (
    <motion.div
      className="relative rounded-3xl border border-white/[0.07] bg-white/[0.025] p-7 text-center"
      initial={{ opacity: 0, y: 30 }}
      animate={seen ? { opacity: 1, y: 0 } : {}}
      transition={{ duration: 0.7, delay: 0.2 + n * 0.15, ease: [0.16, 1, 0.3, 1] }}
    >
      <div className="relative z-10 mx-auto grid size-14 place-items-center rounded-full bg-[#140e0b] text-lg font-semibold text-orange-300 ring-1 ring-orange-400/30">
        {n}
      </div>
      <h3 className="mt-5 text-lg font-semibold">{title}</h3>
      <p className="mt-2 text-[15px] leading-relaxed text-white/55">{body}</p>
      <div className="mt-6 flex h-14 items-center justify-center">{children}</div>
    </motion.div>
  );
}

/** A token being pasted, then the account found. */
function Typing({ active }: { active: boolean }) {
  const [n, setN] = useState(0);
  useEffect(() => {
    if (!active) return;
    let i = 0;
    let timer: ReturnType<typeof setTimeout>;
    const tick = () => {
      i = i >= token.length + 18 ? 0 : i + 1;
      setN(i);
      timer = setTimeout(tick, i === 0 ? 600 : 55);
    };
    timer = setTimeout(tick, 900);
    return () => clearTimeout(timer);
  }, [active]);
  const shown = Math.min(n, token.length);
  const done = n >= token.length;
  return (
    <div className="w-full max-w-[240px] space-y-1.5 text-left">
      <div className="truncate rounded-md bg-black/40 px-2.5 py-1.5 font-mono text-xs text-white/80 ring-1 ring-white/10">
        {token.slice(0, shown).replace(/./g, (c, i) => (i < 5 ? c : "•"))}
        <span className="ml-px inline-block h-3 w-px animate-pulse bg-orange-300 align-middle" />
      </div>
      <motion.div className="text-xs text-emerald-400" animate={{ opacity: done ? 1 : 0 }}>
        ✓ Connected · Acme Inc
      </motion.div>
    </div>
  );
}
