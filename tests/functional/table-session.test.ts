import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { GameController } from '@/game/controllers/GameController';
import { mockLocalStorage } from '../helpers/storage';

vi.mock('howler', () => ({
  Howl: class {
    play = vi.fn();
  },
}));

describe('table session lifecycle (functional)', () => {
  beforeEach(() => {
    mockLocalStorage();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('runs betting → deal → action → settle flow', () => {
    const controller = new GameController();
    controller.startFreePlay({ deckCount: 1, initialOtherPlayers: 0, handsBeforeReshuffle: 30 });

    controller.placeBet(10);
    expect(controller.getSession()?.currentWager).toBe(10);

    controller.deal();
    const session = controller.getSession()!;
    expect(session.dealerCards).toHaveLength(2);
    expect(session.seats[0].hands[0].cards).toHaveLength(2);

    if (session.phase === 'insurance') {
      controller.applyAction('insurance-decline');
    }

    const afterDecline = controller.getSession()!;
    if (afterDecline.phase === 'player-turn') {
      controller.applyAction('stand');
    }

    expect(controller.getSession()?.phase).toBe('settled');
    expect(controller.getSession()?.handsPlayed).toBe(1);
  });

  it('emits count updates after deal', () => {
    const controller = new GameController();
    const counts: number[] = [];
    controller.events.on('count:updated', (state) => counts.push(state.runningCount));

    controller.startFreePlay({ deckCount: 1, initialOtherPlayers: 0 });
    controller.placeBet(10);
    controller.deal();

    expect(counts.length).toBeGreaterThan(0);
  });

  it('continues to next hand in betting phase', () => {
    const controller = new GameController();
    controller.startFreePlay({ deckCount: 1, initialOtherPlayers: 0, handsBeforeReshuffle: 30 });
    controller.placeBet(10);
    controller.deal();

    if (controller.getSession()?.phase === 'insurance') {
      controller.applyAction('insurance-decline');
    }
    if (controller.getSession()?.phase === 'player-turn') {
      controller.applyAction('stand');
    }

    controller.continueToNextHand();
    const session = controller.getSession();
    expect(session?.phase).toBe('betting');
    expect(session?.seats[0].hands).toHaveLength(0);
    expect(session?.currentWager).toBe(0);
  });

  it('tracks hands toward reshuffle threshold across session', () => {
    const controller = new GameController();
    controller.startFreePlay({ deckCount: 6, initialOtherPlayers: 0, handsBeforeReshuffle: 20 });

    for (let i = 0; i < 5; i++) {
      controller.placeBet(10);
      controller.deal();
      if (controller.getSession()?.phase === 'insurance') controller.applyAction('insurance-decline');
      if (controller.getSession()?.phase === 'player-turn') controller.applyAction('stand');
      controller.continueToNextHand();
    }

    const shoe = controller.getSession()?.shoe;
    expect(shoe?.handsDealtSinceShuffle).toBe(5);
    expect(shoe?.reshuffleAt).toBe(20);
  });

  it('emits reshuffle event when hand threshold is reached', () => {
    const controller = new GameController();
    controller.startFreePlay({ deckCount: 6, initialOtherPlayers: 0, handsBeforeReshuffle: 20 });

    const reshuffles: number[] = [];
    controller.events.on('shoe:reshuffled', () => reshuffles.push(1));

    for (let i = 0; i < 20; i++) {
      controller.placeBet(10);
      controller.deal();
      if (controller.getSession()?.phase === 'insurance') controller.applyAction('insurance-decline');
      if (controller.getSession()?.phase === 'player-turn') controller.applyAction('stand');
      controller.continueToNextHand();
      if (reshuffles.length > 0) break;
    }

    expect(reshuffles.length).toBe(1);
  });
});
