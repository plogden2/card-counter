import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { GameController } from '@/game/controllers/GameController';
import { listBetModels, getBetModel } from '@/domain/bet-models';
import { getBetCoaching } from '@/domain/bet-sizing';
import { DEFAULT_TABLE_CONFIG } from '@/domain/table-config';
import { mockLocalStorage } from '../helpers/storage';

vi.mock('howler', () => ({
  Howl: class {
    play = vi.fn();
  },
}));

describe('bet model selection (functional)', () => {
  beforeEach(() => {
    mockLocalStorage();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('lists all three models with educational content', () => {
    const models = listBetModels();
    expect(models).toHaveLength(3);
    for (const model of models) {
      expect(model.name.length).toBeGreaterThan(0);
      expect(model.pros.length).toBeGreaterThanOrEqual(3);
      expect(model.cons.length).toBeGreaterThanOrEqual(3);
      const ev = model.expectedReturnProjection(DEFAULT_TABLE_CONFIG);
      expect(ev.hourlyEVMin).toBeGreaterThan(0);
    }
  });

  it('starts session with profile-selected bet model', () => {
    const controller = new GameController();
    controller.startFreePlay({ deckCount: 6, betModel: 'wonging' });
    expect(controller.getSession()?.currentBetModel).toBe('wonging');
  });

  it('allows switching bet model between hands', () => {
    const controller = new GameController();
    controller.startFreePlay({ deckCount: 1, initialOtherPlayers: 0, betModel: 'spread-table' });

    controller.placeBet(10);
    controller.deal();
    if (controller.getSession()?.phase === 'insurance') controller.applyAction('insurance-decline');
    if (controller.getSession()?.phase === 'player-turn') controller.applyAction('stand');

    controller.startFreePlay({ deckCount: 1, initialOtherPlayers: 0, betModel: 'flat-ramp' });
    expect(controller.getSession()?.currentBetModel).toBe('flat-ramp');

    const spread = getBetModel('spread-table').recommend({
      trueCount: 3,
      bankroll: 1000,
      tableMinBet: 5,
      tableMaxBet: 500,
    });
    const flat = getBetModel('flat-ramp').recommend({
      trueCount: 3,
      bankroll: 1000,
      tableMinBet: 5,
      tableMaxBet: 500,
    });
    expect(spread.min).toBeGreaterThan(flat.min);
  });

  it('produces distinct coaching per model at same true count', () => {
    const ctx = { trueCount: 2, bankroll: 1000, tableMinBet: 5, tableMaxBet: 500 };
    const spread = getBetCoaching(10, 'spread-table', ctx);
    const wong = getBetCoaching(10, 'wonging', ctx);
    expect(spread.recommendation.min).not.toBe(wong.recommendation.min);
    expect(spread.message).toContain('Spread Table');
    expect(wong.message).toContain('Conservative Wonging');
  });
});
