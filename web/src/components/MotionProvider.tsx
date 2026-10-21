"use client";

import { MotionConfig } from "motion/react";
import type { ReactNode } from "react";

/** Honors the system's Reduce Motion setting for every animation. */
export function MotionProvider({ children }: { children: ReactNode }) {
  return <MotionConfig reducedMotion="user">{children}</MotionConfig>;
}
