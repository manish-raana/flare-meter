"use client";

import { useEffect, useState } from "react";

/** How many times FlareMeter.dmg has been downloaded (counted by worker/index.ts), once there are more than 10. */
export function DownloadCount({ className }: { className?: string }) {
  const [count, setCount] = useState<number | null>(null);

  useEffect(() => {
    // Not served by `next dev`, so the count stays hidden there.
    fetch("/api/downloads")
      .then((r) => (r.ok ? r.json() : null))
      .then((data: { downloads?: number } | null) => setCount(data?.downloads ?? null))
      .catch(() => {});
  }, []);

  if (count === null || count <= 10) return null;
  return (
    <span className={className}>
      <span aria-hidden className="text-orange-400">↓</span> {count.toLocaleString("en-US")} downloads
    </span>
  );
}
