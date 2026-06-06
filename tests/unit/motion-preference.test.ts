import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { getTweenDuration, prefersReducedMotion } from '@/lib/motion-preference';

describe('motion preference', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('returns zero duration when reduced motion is enabled explicitly', () => {
    expect(getTweenDuration(300, true)).toBe(0);
  });

  it('returns base duration when reduced motion is disabled explicitly', () => {
    expect(getTweenDuration(300, false)).toBe(300);
  });

  it('reads prefers-reduced-motion media query', () => {
    vi.stubGlobal('window', {
      matchMedia: (query: string) => ({
        matches: query.includes('reduce'),
        media: query,
      }),
    });
    expect(prefersReducedMotion()).toBe(true);
    expect(getTweenDuration(250)).toBe(0);
  });

  it('defaults to full motion when matchMedia is unavailable', () => {
    vi.stubGlobal('window', undefined);
    expect(prefersReducedMotion()).toBe(false);
    expect(getTweenDuration(200)).toBe(200);
  });

  beforeEach(() => {
    vi.unstubAllGlobals();
  });
});
