import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { GameController } from '@/game/controllers/GameController';
import {
  loadProfile,
  saveProfile,
  DEFAULT_PROFILE,
} from '@/persistence/learner-profile';
import {
  saveHandSnapshot,
  loadHandSnapshot,
  clearHandSnapshot,
  createSnapshot,
} from '@/persistence/hand-snapshot';
import { createSession } from '@/domain/blackjack';
import { createRng } from '@/lib/rng';
import { mockLocalStorage } from '../helpers/storage';

vi.mock('howler', () => ({
  Howl: class {
    play = vi.fn();
  },
}));

describe('session persistence (functional)', () => {
  let storage: ReturnType<typeof mockLocalStorage>;

  beforeEach(() => {
    storage = mockLocalStorage();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('round-trips learner profile through localStorage', () => {
    saveProfile({ ...DEFAULT_PROFILE, balance: 842, lastMode: 'free-play' });
    const loaded = loadProfile();
    expect(loaded.balance).toBe(842);
    expect(loaded.lastMode).toBe('free-play');
    expect(loaded.lastSessionAt).toBeDefined();
  });

  it('recovers from corrupted profile JSON', () => {
    storage.store['card-counter:learner-profile'] = '{not valid json';
    expect(loadProfile()).toEqual(DEFAULT_PROFILE);
  });

  it('recovers from invalid schema version', () => {
    storage.store['card-counter:learner-profile'] = JSON.stringify({
      schemaVersion: 2,
      balance: 123,
    });
    expect(loadProfile().balance).toBe(DEFAULT_PROFILE.balance);
  });

  it('saves and loads mid-hand snapshots', () => {
    const session = createSession('free-play', { deckCount: 1 }, 1000, 'spread-table', createRng(1));
    const midHand = { ...session, phase: 'player-turn' as const, activeSeatId: 'learner' };
    saveHandSnapshot(createSnapshot(midHand, 'player-turn', 'learner'));

    const loaded = loadHandSnapshot();
    expect(loaded?.phase).toBe('player-turn');
    expect(loaded?.sessionState.balance).toBe(1000);
    expect(loaded?.activeSeatId).toBe('learner');
  });

  it('rejects corrupted hand snapshots', () => {
    storage.store['card-counter:hand-snapshot'] = JSON.stringify({ bad: true });
    expect(loadHandSnapshot()).toBeNull();
  });

  it('clears snapshot after hand completes', () => {
    const controller = new GameController();
    controller.startFreePlay({ deckCount: 1, initialOtherPlayers: 0 });
    controller.placeBet(10);
    controller.deal();

    if (controller.getSession()?.phase !== 'betting') {
      expect(controller.hasMidHandSnapshot()).toBe(true);
    }

    if (controller.getSession()?.phase === 'insurance') controller.applyAction('insurance-decline');
    if (controller.getSession()?.phase === 'player-turn') controller.applyAction('stand');

    expect(controller.hasMidHandSnapshot()).toBe(false);
  });

  it('supports forfeit and resume mid-hand flow', () => {
    const controller = new GameController();
    controller.startFreePlay({ deckCount: 1, initialOtherPlayers: 0 });
    controller.placeBet(10);
    controller.deal();

    const balanceDuringHand = controller.getSession()?.balance;
    if (controller.getSession()?.phase === 'insurance') {
      controller.applyAction('insurance-decline');
    }

    controller.forfeitMidHand();
    expect(controller.getSession()?.phase).toBe('betting');
    expect(controller.getSession()?.balance).toBe(balanceDuringHand);

    if (controller.getSession()?.phase === 'player-turn') {
      saveHandSnapshot(
        createSnapshot(controller.getSession()!, 'player-turn', 'learner'),
      );
      controller.forfeitMidHand();
      controller.resumeMidHand();
      expect(controller.getSession()?.phase).toBe('player-turn');
    }

    clearHandSnapshot();
    expect(loadHandSnapshot()).toBeNull();
  });

  it('reset bankroll restores $1,000 with confirmation flow', () => {
    const controller = new GameController();
    controller.startFreePlay({ deckCount: 1 });
    controller.getSession();
    saveProfile({ ...DEFAULT_PROFILE, balance: 200 });

    controller.resetBankrollConfirmed();
    expect(controller.getProfile().balance).toBe(1000);
    expect(controller.getSession()?.balance).toBe(1000);
    expect(controller.getSession()?.analytics.at(-1)?.annotation).toBe('bankroll-reset');
  });
});
