import type { SVGProps } from "react";

type P = SVGProps<SVGSVGElement>;

export const CloudIcon = (p: P) => (
  <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden {...p}>
    <path d="M6.6 19a4.6 4.6 0 0 1-.9-9.1 6.4 6.4 0 0 1 12.2-1.6A5.4 5.4 0 0 1 17.6 19H6.6z" />
  </svg>
);

export const WarningCloudIcon = (p: P) => (
  <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden {...p}>
    <path
      fillRule="evenodd"
      d="M6.6 19a4.6 4.6 0 0 1-.9-9.1 6.4 6.4 0 0 1 12.2-1.6A5.4 5.4 0 0 1 17.6 19H6.6zM12 8.2a1 1 0 0 0-1 1v3.6a1 1 0 1 0 2 0V9.2a1 1 0 0 0-1-1zm0 6.6a1.1 1.1 0 1 0 0 2.2 1.1 1.1 0 0 0 0-2.2z"
    />
  </svg>
);

export const WifiIcon = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.2} strokeLinecap="round" aria-hidden {...p}>
    <path d="M2.5 9a14 14 0 0 1 19 0M5.8 12.4a9.2 9.2 0 0 1 12.4 0M9.1 15.8a4.6 4.6 0 0 1 5.8 0" />
    <circle cx="12" cy="19" r="1.1" fill="currentColor" stroke="none" />
  </svg>
);

export const BatteryIcon = (p: P) => (
  <svg viewBox="0 0 28 14" fill="none" aria-hidden {...p}>
    <rect x="0.75" y="0.75" width="23.5" height="12.5" rx="3.5" stroke="currentColor" strokeOpacity={0.55} strokeWidth={1.5} />
    <rect x="3" y="3" width="16" height="8" rx="1.6" fill="currentColor" />
    <path d="M26 4.8v4.4c.9-.3 1.5-1.2 1.5-2.2s-.6-1.9-1.5-2.2z" fill="currentColor" fillOpacity={0.55} />
  </svg>
);

export const RefreshIcon = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.2} strokeLinecap="round" strokeLinejoin="round" aria-hidden {...p}>
    <path d="M20 11a8 8 0 1 0-2.3 5.7M20 4v7h-7" />
  </svg>
);

export const CheckIcon = (p: P) => (
  <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden {...p}>
    <path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm4.7 7.3-5.5 6a1 1 0 0 1-1.5 0l-2.4-2.6a1 1 0 1 1 1.5-1.4l1.6 1.8 4.8-5.2a1 1 0 0 1 1.5 1.4z" />
  </svg>
);
