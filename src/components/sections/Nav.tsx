"use client";

import { motion, useMotionValueEvent, useScroll } from "motion/react";
import Link from "next/link";
import { useState } from "react";
import { site } from "@/lib/site";

export function Nav() {
  const { scrollY } = useScroll();
  const [solid, setSolid] = useState(false);
  useMotionValueEvent(scrollY, "change", (y) => setSolid(y > 24));
  return (
    <motion.header
      className="fixed inset-x-0 top-0 z-50 transition-colors duration-300"
      style={{
        backgroundColor: solid ? "rgba(12,9,8,0.72)" : "rgba(12,9,8,0)",
        backdropFilter: solid ? "blur(18px) saturate(1.4)" : "none",
        borderBottom: solid ? "1px solid rgba(255,255,255,0.06)" : "1px solid transparent",
      }}
    >
      <nav className="mx-auto flex h-16 max-w-6xl items-center gap-6 px-5">
        <Link href="/" className="flex items-center gap-2.5 font-semibold tracking-tight">
          <img src="/icon.png" alt="" className="size-7" />
          {site.name}
        </Link>
        <div className="ml-auto hidden items-center gap-6 text-sm text-white/60 sm:flex">
          <a href="#features" className="hover:text-white">Features</a>
          <a href="#how" className="hover:text-white">How it works</a>
          <a href="#faq" className="hover:text-white">FAQ</a>
        </div>
        <a
          href="#buy"
          className="ml-auto rounded-full bg-white px-4 py-1.5 text-sm font-semibold text-black transition hover:bg-orange-100 sm:ml-0"
        >
          Buy {site.price}
        </a>
      </nav>
    </motion.header>
  );
}
