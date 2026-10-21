"use client";

import { motion, useMotionValueEvent, useTransform, type MotionValue } from "motion/react";
import { useState, type ReactNode } from "react";
import { Bar, Ring, useCountUp } from "@/components/ui/animated";
import { BatteryIcon, CheckIcon, CloudIcon, RefreshIcon, WarningCloudIcon, WifiIcon } from "@/components/ui/icons";
import { formatNumber, formatPercent, tone } from "@/lib/format";
import { fraction, sampleMetrics, type Metric } from "@/lib/sample";

// Recreations of FlareMeter's menu bar item, panel and widgets (dark appearance), driven by motion values.

const top = sampleMetrics[0];
const withLimits = sampleMetrics.filter((m) => m.limit);
const amount = (m: Metric, sep = " / ") =>
  m.limit ? `${formatNumber(m.value, m.unit)}${sep}${formatNumber(m.limit, m.unit)}` : formatNumber(m.value, m.unit);

/** The menu bar item: a cloud (a warning cloud past 85%) and the fullest metric's percentage. */
export function MenuBarItem({ value, active = false }: { value: MotionValue<number>; active?: boolean }) {
  const text = useTransform(value, formatPercent);
  const [warn, setWarn] = useState(false);
  useMotionValueEvent(value, "change", (v) => setWarn(v >= 0.85));
  return (
    <motion.div
      className={`flex items-center gap-1 rounded-md px-2 py-0.5 ${active ? "bg-white/20" : ""}`}
      animate={warn ? { color: ["#ffffff", "#ff8a80", "#ffffff"] } : { color: "#ffffff" }}
      transition={warn ? { duration: 1.2, repeat: Infinity } : { duration: 0.3 }}
    >
      {warn ? <WarningCloudIcon className="size-[17px]" /> : <CloudIcon className="size-[17px]" />}
      <motion.span className="text-[13px] font-medium tabular-nums">{text}</motion.span>
    </motion.div>
  );
}

/** The right end of a macOS menu bar with FlareMeter's item. */
export function MenuBar({ value, active }: { value: MotionValue<number>; active?: boolean }) {
  return (
    <div className="flex h-7 items-center justify-end gap-4 bg-black/25 px-4 text-[13px] font-medium text-white backdrop-blur-xl">
      <MenuBarItem value={value} active={active} />
      <WifiIcon className="size-4" />
      <BatteryIcon className="h-3.5 w-7" />
      <span className="tabular-nums">Mon 9:41</span>
    </div>
  );
}

function Card({ className = "", children }: { className?: string; children: ReactNode }) {
  return (
    <div className={`rounded-[22px] bg-[#1f1c1a]/90 p-4 text-white shadow-[0_30px_80px_-30px_rgba(0,0,0,0.8)] ring-1 ring-white/10 backdrop-blur-2xl ${className}`}>
      {children}
    </div>
  );
}

function Row({ metric, active, delay, size = 11 }: { metric: Metric; active: boolean; delay: number; size?: number }) {
  const v = useCountUp(fraction(metric), active, delay);
  const pct = useTransform(v, formatPercent);
  const color = useTransform(v, tone);
  return (
    <div className="space-y-1">
      <div className="flex items-baseline gap-1.5" style={{ fontSize: size }}>
        <span className="truncate">{metric.label}</span>
        <span className="ml-auto shrink-0 tabular-nums text-white/55">{amount(metric)}</span>
        <motion.span className="w-[34px] shrink-0 text-right font-semibold tabular-nums" style={{ color }}>
          {pct}
        </motion.span>
      </div>
      <Bar value={v} />
    </div>
  );
}

function Grid({ metrics, size = 10 }: { metrics: Metric[]; size?: number }) {
  return (
    <div className="grid grid-cols-2 gap-x-3.5 gap-y-1" style={{ fontSize: size }}>
      {metrics.map((m) => (
        <div key={m.id} className="flex gap-1">
          <span className="truncate text-white/55">{m.label}</span>
          <span className={`ml-auto tabular-nums ${m.id === "workerErrors" ? "text-orange-400" : ""}`}>
            {formatNumber(m.value, m.unit)}
          </span>
        </div>
      ))}
    </div>
  );
}

const SectionTitle = ({ children }: { children: ReactNode }) => (
  <div className="text-[9px] font-semibold uppercase tracking-[0.06em] text-white/35">{children}</div>
);

function Header({ right }: { right: ReactNode }) {
  return (
    <div className="flex items-center gap-1.5 text-[12px] font-semibold">
      <CloudIcon className="size-3.5 text-orange-500" />
      FlareMeter
      <span className="ml-auto flex items-center gap-2 text-[10px] font-normal text-white/50">
        {right}
        <RefreshIcon className="size-3" />
      </span>
    </div>
  );
}

function Footer() {
  return (
    <div className="flex items-center text-[10px] text-white/50">
      <span className="tabular-nums">9:41</span>
      <span className="ml-auto flex items-center gap-1">
        <CheckIcon className="size-3" /> Within plan
      </span>
    </div>
  );
}

/** Large widget. `value` overrides the fullest metric's fraction (for scroll-driven scenes). */
export function LargeWidget({ active, value }: { active: boolean; value?: MotionValue<number> }) {
  const counted = useCountUp(fraction(top), active);
  const v = value ?? counted;
  const topAmount = useTransform(v, (f) => `${formatNumber(f * top.limit!, top.unit)} of ${formatNumber(top.limit!, top.unit)}`);
  const bars = withLimits.slice(1, 5);
  const rest = sampleMetrics.filter((m) => m !== top && !bars.includes(m));
  return (
    <Card className="flex h-[382px] w-[364px] flex-col gap-2.5">
      <Header right="This month" />
      <div className="flex items-center gap-3">
        <Ring value={v} size={58} stroke={6.5} fontSize={15.5} />
        <div>
          <SectionTitle>Fullest</SectionTitle>
          <div className="text-[13px] font-semibold">{top.label}</div>
          <motion.div className="text-[11px] tabular-nums text-white/55">{topAmount}</motion.div>
        </div>
      </div>
      <div className="space-y-[7px]">
        {bars.map((m, i) => (
          <Row key={m.id} metric={m} active={active} delay={0.15 + i * 0.08} />
        ))}
      </div>
      <div className="space-y-1.5">
        <SectionTitle>Under 1% of plan</SectionTitle>
        <Grid metrics={rest} />
      </div>
      <div className="mt-auto">
        <Footer />
      </div>
    </Card>
  );
}

export function MediumWidget({ active }: { active: boolean }) {
  const v = useCountUp(fraction(top), active, 0.1);
  return (
    <Card className="flex h-[170px] w-[364px] flex-col gap-2">
      <Header right="This month" />
      <div className="flex items-center gap-3.5">
        <div className="w-[92px] space-y-1">
          <Ring value={v} size={54} stroke={6} fontSize={14.5} />
          <div className="text-[11px] font-semibold leading-tight">{top.label}</div>
        </div>
        <div className="flex-1 space-y-[7px]">
          {withLimits.slice(1, 4).map((m, i) => (
            <Row key={m.id} metric={m} active={active} delay={0.2 + i * 0.08} />
          ))}
        </div>
      </div>
      <div className="mt-auto">
        <Footer />
      </div>
    </Card>
  );
}

export function SmallWidget({ active }: { active: boolean }) {
  const v = useCountUp(fraction(top), active, 0.2);
  return (
    <Card className="flex h-[170px] w-[170px] flex-col">
      <div className="flex items-center gap-1.5 text-[12px] font-semibold">
        <CloudIcon className="size-3.5 text-orange-500" />
        Oct
        <span className="ml-auto flex items-center gap-1.5 text-[10px] font-normal text-white/50">
          9:41 <RefreshIcon className="size-3" />
        </span>
      </div>
      <div className="mt-auto space-y-1.5">
        <Ring value={v} size={66} stroke={7} fontSize={18} />
        <div>
          <div className="truncate text-[12px] font-semibold">{top.label}</div>
          <div className="text-[10px] tabular-nums text-white/55">{amount(top, " of ")}</div>
        </div>
      </div>
    </Card>
  );
}

/** The panel that drops from the menu bar item. */
export function Panel({ active }: { active: boolean }) {
  const v = useCountUp(fraction(top), active, 0.1);
  const bars = withLimits.slice(1).filter((m) => fraction(m) >= 0.01);
  const rest = sampleMetrics.filter((m) => m !== top && !bars.includes(m));
  return (
    <div className="w-[340px] space-y-3 rounded-2xl bg-[#232020]/92 p-3.5 text-white shadow-[0_40px_100px_-30px_rgba(0,0,0,0.9)] ring-1 ring-white/10 backdrop-blur-2xl">
      <div className="flex items-center gap-2.5">
        <div className="grid size-7 place-items-center rounded-[7px] bg-gradient-to-b from-orange-400 to-orange-600">
          <CloudIcon className="size-4 text-white" />
        </div>
        <div>
          <div className="text-[14px] font-semibold leading-tight">FlareMeter</div>
          <div className="text-[11px] text-white/50">This month so far</div>
        </div>
        <RefreshIcon className="ml-auto size-3.5 text-white/60" />
      </div>
      <div className="flex items-center gap-3.5 rounded-[10px] bg-white/[0.06] p-3">
        <Ring value={v} size={64} stroke={7} fontSize={17} />
        <div>
          <SectionTitle>Fullest</SectionTitle>
          <div className="text-[14px] font-semibold">{top.label}</div>
          <div className="text-[12px] tabular-nums text-white/55">{amount(top, " of ")}</div>
        </div>
      </div>
      <div className="space-y-2">
        {bars.map((m, i) => (
          <Row key={m.id} metric={m} active={active} delay={0.25 + i * 0.1} size={12} />
        ))}
      </div>
      <div className="space-y-1.5">
        <SectionTitle>Under 1% of plan</SectionTitle>
        <Grid metrics={rest} size={11} />
      </div>
      <div className="flex items-center gap-3 border-t border-white/10 pt-2.5 text-[11px] text-white/50">
        <span>Updated now</span>
        <span className="flex items-center gap-1">
          <CheckIcon className="size-3" /> Within plan
        </span>
      </div>
    </div>
  );
}
