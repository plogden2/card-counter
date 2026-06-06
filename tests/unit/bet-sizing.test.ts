import { describe, it, expect } from 'vitest';
import {
  getRecommendation,
  classifyBet,
  getBetCoaching,
} from '@/domain/bet-sizing';
import type { BetRecommendation } from '@/domain/bet-models';

const ctx = (trueCount: number, bankroll = 1000) => ({
  trueCount,
  bankroll,
  tableMinBet: 5,
  tableMaxBet: 500,
});

describe('bet sizing', () => {
  it('returns model-specific recommendations', () => {
    const spread = getRecommendation('spread-table', ctx(3));
    const wong = getRecommendation('wonging', ctx(0));
    expect(spread.min).toBe(60);
    expect(wong.min).toBe(5);
  });

  describe('classifyBet', () => {
    const recommendation: BetRecommendation = { min: 20, max: 40, unitSize: 10, floorApplied: false };

    it('classifies under bets', () => {
      expect(classifyBet(10, recommendation)).toBe('under');
    });

    it('classifies optimal bets', () => {
      expect(classifyBet(25, recommendation)).toBe('optimal');
      expect(classifyBet(20, recommendation)).toBe('optimal');
      expect(classifyBet(40, recommendation)).toBe('optimal');
    });

    it('classifies over bets', () => {
      expect(classifyBet(50, recommendation)).toBe('over');
    });
  });

  it('provides coaching for under-bets at positive counts', () => {
    const coaching = getBetCoaching(10, 'spread-table', ctx(3));
    expect(coaching.classification).toBe('under');
    expect(coaching.message).toContain('below');
    expect(coaching.message).toContain('Spread Table');
  });

  it('provides coaching for optimal bets', () => {
    const rec = getRecommendation('spread-table', ctx(2));
    const coaching = getBetCoaching(rec.min, 'spread-table', ctx(2));
    expect(coaching.classification).toBe('optimal');
    expect(coaching.message).toContain('matches');
  });

  it('appends floor message when table minimum is applied', () => {
    const coaching = getBetCoaching(5, 'spread-table', {
      ...ctx(0),
      bankroll: 1000,
      tableMinBet: 100,
      tableMaxBet: 500,
    });
    if (coaching.recommendation.floorApplied) {
      expect(coaching.message).toContain('Table minimum applied');
    } else {
      const forced: BetRecommendation = { min: 100, max: 200, unitSize: 10, floorApplied: true };
      const classification = classifyBet(5, forced);
      expect(classification).toBe('under');
    }
  });

  it('handles optimal bet below table minimum edge case', () => {
    const recommendation = getRecommendation('spread-table', {
      trueCount: 0,
      bankroll: 1000,
      tableMinBet: 50,
      tableMaxBet: 500,
    });
    expect(recommendation.min).toBeGreaterThanOrEqual(50);
    expect(classifyBet(25, recommendation)).toBe('under');
  });
});
