"use client";

import { motion } from "motion/react";

const items = [
  "Worker requests", "Worker errors", "Durable Object requests", "DO rows read", "DO rows written", "DO storage",
  "KV reads", "KV writes", "D1 rows read", "D1 rows written", "Workers AI neurons",
];

/** An endless row of what FlareMeter tracks. */
export function Ticker() {
  return (
    <div className="relative overflow-hidden border-y border-white/5 py-5 [mask-image:linear-gradient(to_right,transparent,black_12%,black_88%,transparent)]">
      <motion.div
        className="flex w-max gap-10 whitespace-nowrap text-sm font-medium text-white/45"
        animate={{ x: ["0%", "-50%"] }}
        transition={{ duration: 40, repeat: Infinity, ease: "linear" }}
      >
        {[...items, ...items].map((t, i) => (
          <span key={i} className="flex items-center gap-10">
            {t}
            <span className="size-1 rounded-full bg-orange-500/70" />
          </span>
        ))}
      </motion.div>
    </div>
  );
}
