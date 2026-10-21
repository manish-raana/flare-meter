"use client";

import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { Reveal } from "@/components/ui/animated";
import { faqs } from "@/lib/faqs";
import { site } from "@/lib/site";


export function FAQ() {
  const [open, setOpen] = useState<number | null>(0);
  return (
    <section id="faq" className="mx-auto max-w-3xl scroll-mt-24 px-5 py-28">
      <Reveal className="text-center">
        <h2 className="text-4xl font-semibold tracking-tight sm:text-5xl">Questions</h2>
      </Reveal>
      <div className="mt-12 divide-y divide-white/[0.07] rounded-3xl border border-white/[0.07] bg-white/[0.02]">
        {faqs.map((f, i) => (
          <div key={f.q}>
            <button
              className="flex w-full items-center gap-4 px-6 py-5 text-left text-[17px] font-medium"
              onClick={() => setOpen(open === i ? null : i)}
              aria-expanded={open === i}
            >
              {f.q}
              <motion.span className="ml-auto text-xl text-white/40" animate={{ rotate: open === i ? 45 : 0 }}>
                +
              </motion.span>
            </button>
            <AnimatePresence initial={false}>
              {open === i && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: "auto", opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
                  className="overflow-hidden"
                >
                  <p className="px-6 pb-5 leading-relaxed text-white/55">{f.a}</p>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        ))}
      </div>
      <p className="mt-8 text-center text-white/45">
        Something else? <a className="text-orange-300 hover:underline" href={`mailto:${site.supportEmail}`}>{site.supportEmail}</a>
      </p>
    </section>
  );
}
