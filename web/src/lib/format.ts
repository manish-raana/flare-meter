export type Unit = "count" | "bytes" | "neurons";

/** The app's number style: 1.2k, 68k, 1.5M, 2.1B, or bytes. */
export function formatNumber(v: number, unit: Unit = "count"): string {
  if (unit === "bytes") {
    if (v === 0) return "0 B";
    const units = ["B", "kB", "MB", "GB", "TB"];
    const i = Math.min(units.length - 1, Math.floor(Math.log10(v) / 3));
    return `${(v / 1000 ** i).toFixed(i === 0 ? 0 : 1)} ${units[i]}`;
  }
  const a = Math.abs(v);
  if (a >= 1e9) return `${(v / 1e9).toFixed(1)}B`;
  if (a >= 1e6) return `${(v / 1e6).toFixed(1)}M`;
  if (a >= 1e4) return `${(v / 1e3).toFixed(0)}k`;
  if (a >= 1e3) return `${(v / 1e3).toFixed(1)}k`;
  return v.toFixed(0);
}

export function formatPercent(f: number): string {
  return f > 0 && f < 0.01 ? "<1%" : `${Math.round(f * 100)}%`;
}

/** Green under 60%, orange under 85%, red past that (the app's colors). */
export function tone(f: number): string {
  if (f >= 0.85) return "#ff453a";
  if (f >= 0.6) return "#ff9f0a";
  return "#30d158";
}
