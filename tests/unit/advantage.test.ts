import { describe, it, expect } from 'vitest';
import { estimateAdvantage, normalizedAdvantage } from '@/domain/advantage';

describe('advantage estimation', () => {
  it('estimates advantage as 0.5% per true count point', () => {
    expect(estimateAdvantage(0)).toBe(0);
    expect(estimateAdvantage(2)).toBe(1);
    expect(estimateAdvantage(-4)).toBe(-2);
  });

  it('normalizes advantage below worthwhile threshold', () => {
    expect(normalizedAdvantage(0)).toBeCloseTo(0.67, 1);
    expect(normalizedAdvantage(-2)).toBe(0);
    expect(normalizedAdvantage(0, 2)).toBe(0.5);
  });

  it('normalizes advantage at and above worthwhile threshold', () => {
    expect(normalizedAdvantage(1)).toBe(0.5);
    expect(normalizedAdvantage(3)).toBe(0.7);
    expect(normalizedAdvantage(10)).toBe(1);
  });

  it('uses wonging threshold when assessing stay scores', () => {
    expect(normalizedAdvantage(0, 1)).toBeCloseTo(0.67, 1);
    expect(normalizedAdvantage(1, 1)).toBe(0.5);
  });
});
