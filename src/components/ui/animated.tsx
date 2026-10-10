"use client";

import { animate, motion, useInView, useMotionValue, useTransform, type MotionValue } from "motion/react";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { formatPercent, tone } from "@/lib/format";

/** A motion value that animates from 0 to `target` once `active` turns true. */
export function useCountUp(target: number, active: boolean, delay = 0, duration = 1.6) {
  const value = useMotionValue(0);
  useEffect(() => {
    if (!active) return;
    const controls = animate(value, target, { duration, delay, ease: [0.16, 1, 0.3, 1] });
    return () => controls.stop();
  }, [active, target, delay, duration, value]);
  return value;
}

/** In view once (with a margin), for starting animations. */
export function useSeen<T extends Element>(margin = "-10% 0px") {
  const ref = useRef<T>(null);
  const seen = useInView(ref, { once: true, margin: margin as `${number}px` });
  return [ref, seen] as const;
}

/** A ring filled to `value` (0…1+), with the percentage inside, colored like the app. */
export function Ring({ value, size = 64, stroke = 7, fontSize = 16 }: {
  value: MotionValue<number>;
  size?: number;
  stroke?: number;
  fontSize?: number;
}) {
  const r = (size - stroke) / 2;
  const length = useTransform(value, (v) => Math.max(0.004, Math.min(1, v)));
  const color = useTransform(value, tone);
  const text = useTransform(value, formatPercent);
  return (
    <div className="relative shrink-0" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" strokeWidth={stroke} className="stroke-white/10" />
        <motion.circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          strokeWidth={stroke}
          strokeLinecap="round"
          style={{ pathLength: length, stroke: color }}
        />
      </svg>
      <motion.span className="absolute inset-0 grid place-items-center font-bold tabular-nums tracking-tight" style={{ fontSize }}>
        {text}
      </motion.span>
    </div>
  );
}

/** A capsule bar filled to `value`. */
export function Bar({ value, height = 4 }: { value: MotionValue<number>; height?: number }) {
  const scale = useTransform(value, (v) => Math.max(0.012, Math.min(1, v)));
  const color = useTransform(value, tone);
  return (
    <div className="w-full overflow-hidden rounded-full bg-white/10" style={{ height }}>
      <motion.div className="h-full w-full origin-left rounded-full" style={{ scaleX: scale, backgroundColor: color }} />
    </div>
  );
}

/** Lays out fixed-size artwork and scales it down to fit narrower screens. */
export function ScaledStage({ width, height, children, className }: {
  width: number;
  height: number;
  children: ReactNode;
  className?: string;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(1);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const ro = new ResizeObserver(([entry]) => setScale(Math.min(1, entry.contentRect.width / width)));
    ro.observe(el);
    return () => ro.disconnect();
  }, [width]);
  return (
    <div ref={ref} className={className} style={{ height: height * scale }}>
      <div style={{ width, height, transform: `scale(${scale})`, transformOrigin: "top left" }}>{children}</div>
    </div>
  );
}

/** Fades and lifts its children in when scrolled into view. */
export function Reveal({ children, delay = 0, className, y = 24 }: { children: ReactNode; delay?: number; className?: string; y?: number }) {
  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y, filter: "blur(6px)" }}
      whileInView={{ opacity: 1, y: 0, filter: "blur(0px)" }}
      viewport={{ once: true, margin: "-80px" }}
      transition={{ duration: 0.8, delay, ease: [0.16, 1, 0.3, 1] }}
    >
      {children}
    </motion.div>
  );
}
