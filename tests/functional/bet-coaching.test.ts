import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { GameController } from '@/game/controllers/GameController';
import { mockLocalStorage } from '../helpers/storage';

vi.mock('howler', () => ({
  Howl: class {
    play = vi.fn();
  },
}));

describe('bet coaching (functional)', () => {
  beforeEach(() => {
    mockLocalStorage();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('emits coaching message after hand settles', () => {
    const controller = new GameController();
    const messages: string[] = [];
    controller.events.on('coaching:message', ({ text, type }) => {
      if (type === 'bet') messages.push(text);
    });

    controller.startFreePlay({ deckCount: 1, initialOtherPlayers: 0 });
    controller.placeBet(10);
    controller.deal();

    if (controller.getSession()?.phase === 'insurance') {
      controller.applyAction('insurance-decline');
    }
    if (controller.getSession()?.phase === 'player-turn') {
      controller.applyAction('stand');
    }

    expect(messages.length).toBe(1);
    expect(messages[0]).toMatch(/Under-bet|Over-bet|Optimal bet/);
  });

  it('records analytics on hand settle', () => {
    const controller = new GameController();
    const analytics: number[] = [];
    controller.events.on('hand:settled', (point) => analytics.push(point.handIndex));

    controller.startFreePlay({ deckCount: 1, initialOtherPlayers: 0 });
    controller.placeBet(10);
    controller.deal();
    if (controller.getSession()?.phase === 'insurance') controller.applyAction('insurance-decline');
    if (controller.getSession()?.phase === 'player-turn') controller.applyAction('stand');

    expect(analytics).toEqual([1]);
    expect(controller.getSession()?.analytics).toHaveLength(1);
  });

  it('persists balance to profile after settle', () => {
    const controller = new GameController();
    controller.startFreePlay({ deckCount: 1, initialOtherPlayers: 0 });
    controller.placeBet(10);
    controller.deal();
    if (controller.getSession()?.phase === 'insurance') controller.applyAction('insurance-decline');
    if (controller.getSession()?.phase === 'player-turn') controller.applyAction('stand');

    const sessionBalance = controller.getSession()?.balance;
    expect(controller.getProfile().balance).toBe(sessionBalance);
  });
});
