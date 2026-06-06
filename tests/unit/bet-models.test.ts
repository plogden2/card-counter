import { describe, it, expect } from 'vitest';
import { getBetModel, listBetModels } from '@/domain/bet-models';
import { DEFAULT_TABLE_CONFIG } from '@/domain/table-config';

const ctx = (trueCount: number) => ({
  trueCount,
  bankroll: 1000,
  tableMinBet: 5,
  tableMaxBet: 500,
});

describe('bet models', () => {
  it('exposes three selectable models', () => {
    const models = listBetModels();
    expect(models).toHaveLength(3);
    expect(models.map((m) => m.id)).toEqual(['spread-table', 'flat-ramp', 'wonging']);
  });

  it('each model has pros, cons, and EV projection', () => {
    for (const model of listBetModels()) {
      expect(model.pros.length).toBeGreaterThan(0);
      expect(model.cons.length).toBeGreaterThan(0);
      const ev = model.expectedReturnProjection(DEFAULT_TABLE_CONFIG);
      expect(ev.hourlyEVMax).toBeGreaterThan(ev.hourlyEVMin);
    }
  });

  describe('spread-table recommendations TC −6..+8', () => {
    const model = getBetModel('spread-table');

    it.each([
      [-6, 10],
      [-1, 10],
      [0, 10],
      [1, 20],
      [2, 40],
      [3, 60],
      [4, 80],
      [8, 80],
    ])('TC %i recommends min $%i', (tc, expectedMin) => {
      const rec = model.recommend(ctx(tc));
      expect(rec.min).toBe(expectedMin);
      expect(rec.unitSize).toBe(10);
    });
  });

  describe('flat-ramp recommendations TC −6..+8', () => {
    const model = getBetModel('flat-ramp');

    it('ramps units with positive true count', () => {
      expect(model.recommend(ctx(-3)).min).toBe(10);
      expect(model.recommend(ctx(3)).min).toBe(30);
      expect(model.recommend(ctx(8)).min).toBe(80);
    });
  });

  describe('wonging recommendations TC −6..+8', () => {
    const model = getBetModel('wonging');

    it('bets table minimum below TC +1', () => {
      for (const tc of [-6, -1, 0]) {
        const rec = model.recommend(ctx(tc));
        expect(rec.min).toBe(5);
        expect(rec.floorApplied).toBe(false);
      }
    });

    it('ramps above wong threshold', () => {
      expect(model.recommend(ctx(1)).min).toBe(10);
      expect(model.recommend(ctx(4)).min).toBe(60);
    });
  });
});
