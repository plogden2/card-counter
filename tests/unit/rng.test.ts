import { describe, it, expect } from 'vitest';
import { createRng, shuffle } from '@/lib/rng';

describe('seedable RNG', () => {
  it('produces deterministic sequences for the same seed', () => {
    const a = createRng(42);
    const b = createRng(42);
    const seqA = Array.from({ length: 5 }, () => a.next());
    const seqB = Array.from({ length: 5 }, () => b.next());
    expect(seqA).toEqual(seqB);
  });

  it('produces different sequences for different seeds', () => {
    const a = createRng(1);
    const b = createRng(2);
    expect(a.next()).not.toBe(b.next());
  });

  it('returns values in [0, 1)', () => {
    const rng = createRng(99);
    for (let i = 0; i < 100; i++) {
      const value = rng.next();
      expect(value).toBeGreaterThanOrEqual(0);
      expect(value).toBeLessThan(1);
    }
  });

  it('nextInt returns integers in [0, max)', () => {
    const rng = createRng(7);
    for (let i = 0; i < 50; i++) {
      const value = rng.nextInt(10);
      expect(value).toBeGreaterThanOrEqual(0);
      expect(value).toBeLessThan(10);
      expect(Number.isInteger(value)).toBe(true);
    }
  });

  it('nextInt throws when max is not positive', () => {
    const rng = createRng(1);
    expect(() => rng.nextInt(0)).toThrow(RangeError);
    expect(() => rng.nextInt(-1)).toThrow(RangeError);
  });

  it('shuffle is deterministic with seeded RNG', () => {
    const items = [1, 2, 3, 4, 5, 6, 7, 8];
    const a = shuffle(items, createRng(123));
    const b = shuffle(items, createRng(123));
    expect(a).toEqual(b);
  });

  it('shuffle preserves all elements', () => {
    const items = [1, 2, 3, 4, 5, 6, 7, 8];
    const shuffled = shuffle(items, createRng(55));
    expect([...shuffled].sort((a, b) => a - b)).toEqual(items);
    expect(shuffled).toHaveLength(items.length);
  });
});
