export function prefersReducedMotion(): boolean {
  if (typeof window === 'undefined' || !window.matchMedia) return false;
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

export function getTweenDuration(baseMs: number, motionReduced?: boolean): number {
  if (motionReduced ?? prefersReducedMotion()) return 0;
  return baseMs;
}
