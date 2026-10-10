import type { Unit } from "./format";

export type Metric = { id: string; label: string; value: number; limit?: number; unit?: Unit };

/** The same sample month the app's screenshots use (Workers Paid). */
export const sampleMetrics: Metric[] = [
  { id: "aiNeurons", label: "Workers AI neurons", value: 109_000, limit: 300_000, unit: "neurons" },
  { id: "doRequests", label: "DO requests", value: 97_000, limit: 1_000_000 },
  { id: "workerRequests", label: "Worker requests", value: 68_000, limit: 10_000_000 },
  { id: "kvReads", label: "KV reads", value: 42_000, limit: 10_000_000 },
  { id: "doRowsWritten", label: "DO rows written", value: 158_000, limit: 50_000_000 },
  { id: "doRowsRead", label: "DO rows read", value: 33_700_000, limit: 25_000_000_000 },
  { id: "d1RowsRead", label: "D1 rows read", value: 1_200_000, limit: 25_000_000_000 },
  { id: "kvWrites", label: "KV writes", value: 467, limit: 1_000_000 },
  { id: "d1RowsWritten", label: "D1 rows written", value: 786, limit: 50_000_000 },
  { id: "workerErrors", label: "Worker errors", value: 329 },
];

export const fraction = (m: Metric) => (m.limit ? m.value / m.limit : 0);
