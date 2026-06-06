import { describe, it, expect, afterEach, vi, beforeEach } from 'vitest';
import { bootControllerHarness, type ControllerHarness } from '../helpers/scene-simulator';
import { mockLocalStorage } from '../helpers/storage';
import { GameController } from '@/game/controllers/GameController';
import { saveProfile, DEFAULT_PROFILE } from '@/persistence/learner-profile';
import { saveHandSnapshot, createSnapshot } from '@/persistence/hand-snapshot';
import { createSession } from '@/domain/blackjack';
import { createRng } from '@/lib/rng';
import type { Card } from '@/domain/card';

vi.mock('howler', () => ({
  Howl: class {
    play = vi.fn();
  },
}));

const card = (rank: Card['rank'], suit: Card['suit'] = 'hearts'): Card => ({ suit, rank });

describe('bankroll flow (integration)', () => {
  let harness: ControllerHarness | null = null;

  beforeEach(() => {
    mockLocalStorage();
  });

  afterEach(() => {
    harness?.destroy();
    harness = null;
    vi.unstubAllGlobals();
  });

  it('persists balance across controller reload', () => {
    harness = bootControllerHarness();
    harness.simulator.clickFreePlay();
    harness.simulator.clickStartTable({ deckCount: 1, initialOtherPlayers: 0 });
    harness.simulator.clickDeal();
    harness.simulator.settleHand();

    const balanceAfterHand = harness.controller.getSession()?.balance;
    harness.destroy();
    harness = null;

    const reloaded = new GameController();
    expect(reloaded.getProfile().balance).toBe(balanceAfterHand);
  });

  it('shows mid-hand recovery prompt when snapshot exists', () => {
    const session = createSession('free-play', { deckCount: 1 }, 1000, 'spread-table', createRng(1));
    const midHand = {
      ...session,
      phase: 'player-turn' as const,
      activeSeatId: 'learner',
      currentWager: 25,
      dealerCards: [card('10'), card('6')],
      seats: [
        {
          id: 'learner',
          isLearner: true,
          dogBreed: 'learner-dog',
          hands: [
            {
              cards: [card('9'), card('7')],
              wager: 25,
              status: 'active' as const,
              isSplit: false,
              ownerSeatId: 'learner',
            },
          ],
        },
      ],
    };
    saveHandSnapshot(createSnapshot(midHand, 'player-turn', 'learner'));

    harness = bootControllerHarness();
    harness.simulator.clickFreePlay();
    harness.simulator.clickStartTable({ deckCount: 1, initialOtherPlayers: 0 });

    expect(harness.simulator.shouldShowRecoveryDialog()).toBe(true);
  });

  it('forfeits mid-hand and restores pre-deal balance', () => {
    harness = bootControllerHarness();
    harness.simulator.clickFreePlay();
    harness.simulator.clickStartTable({ deckCount: 1, initialOtherPlayers: 0 });

    const balanceBefore = harness.controller.getSession()?.balance;
    harness.simulator.clickDeal();

    if (harness.controller.getSession()?.phase !== 'betting') {
      harness.controller.forfeitMidHand();
      expect(harness.controller.getSession()?.phase).toBe('betting');
      expect(harness.controller.getSession()?.balance).toBe(balanceBefore);
      expect(harness.controller.hasMidHandSnapshot()).toBe(false);
    }
  });

  it('refunds insurance wager on forfeit after accepting insurance', () => {
    const controller = new GameController();
    controller.startFreePlay({ deckCount: 1, initialOtherPlayers: 0 });
    controller.placeBet(20);
    controller.deal();

    const balanceBeforeDeal = 1000;
    if (controller.getSession()?.phase === 'insurance') {
      controller.applyAction('insurance-accept');
      expect(controller.getSession()?.seats[0].hands[0].insuranceWager).toBe(10);
      controller.forfeitMidHand();
      expect(controller.getSession()?.balance).toBe(balanceBeforeDeal);
      expect(controller.getSession()?.phase).toBe('betting');
      expect(controller.getSession()?.seats[0].hands).toHaveLength(0);
    }
  });

  it('resets bankroll with confirmation restoring $1,000', () => {
    saveProfile({ ...DEFAULT_PROFILE, balance: 350 });
    harness = bootControllerHarness();
    harness.simulator.clickFreePlay();
    harness.simulator.clickStartTable({ deckCount: 1, initialOtherPlayers: 0 });

    harness.simulator.clickResetConfirm();

    expect(harness.controller.getProfile().balance).toBe(1000);
    expect(harness.controller.getSession()?.balance).toBe(1000);
  });
});
