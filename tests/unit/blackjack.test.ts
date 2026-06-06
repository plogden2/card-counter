import { describe, it, expect } from 'vitest';
import { createRng } from '@/lib/rng';
import {
  createSession,
  placeBet,
  dealInitial,
  applyAction,
  settleHand,
} from '@/domain/blackjack';
import type { SessionState } from '@/domain/session';
import type { Card } from '@/domain/card';

const card = (rank: Card['rank'], suit: Card['suit'] = 'hearts'): Card => ({ suit, rank });

function baseSession(): SessionState {
  return createSession(
    'free-play',
    { deckCount: 1, initialOtherPlayers: 0, handsBeforeReshuffle: 30 },
    1000,
    'spread-table',
    createRng(99),
  );
}

function insuranceSession(dealerHole: Card, learnerCards: Card[]): SessionState {
  const session = baseSession();
  return {
    ...session,
    phase: 'insurance',
    balance: 1000,
    currentWager: 20,
    dealerCards: [card('A', 'spades'), dealerHole],
    seats: [
      {
        id: 'learner',
        isLearner: true,
        dogBreed: 'learner-dog',
        hands: [
          {
            cards: learnerCards,
            wager: 20,
            status: 'active',
            isSplit: false,
            ownerSeatId: 'learner',
          },
        ],
      },
    ],
  };
}

describe('blackjack session flow', () => {
  it('creates a session in betting phase', () => {
    const session = baseSession();
    expect(session.phase).toBe('betting');
    expect(session.balance).toBe(1000);
    expect(session.seats).toHaveLength(1);
  });

  it('clamps bets to table min/max and balance', () => {
    let session = baseSession();
    session = placeBet(session, 3);
    expect(session.currentWager).toBe(5);

    session = placeBet(session, 10_000);
    expect(session.currentWager).toBe(500);
  });

  it('requires a bet before dealing', () => {
    const session = baseSession();
    expect(() => dealInitial(session, createRng(1))).toThrow('Must place bet');
  });

  it('deals initial cards and enters player turn or insurance', () => {
    let session = placeBet(baseSession(), 10);
    session = dealInitial(session, createRng(42));

    expect(session.seats[0].hands[0].cards).toHaveLength(2);
    expect(session.dealerCards).toHaveLength(2);
    expect(['insurance', 'player-turn']).toContain(session.phase);
    expect(session.countState.cardsSeen).toBeGreaterThan(0);
  });

  it('allows hit and stand during player turn', () => {
    let session = placeBet(baseSession(), 10);
    session = dealInitial(session, createRng(42));

    if (session.phase === 'insurance') {
      session = applyAction(session, 'learner', 'insurance-decline', createRng(42));
    }

    if (session.phase === 'player-turn') {
      session = applyAction(session, 'learner', 'hit', createRng(42));
      expect(session.seats[0].hands[0].cards.length).toBeGreaterThanOrEqual(2);
      session = applyAction(session, 'learner', 'stand', createRng(42));
      expect(session.phase).toBe('settled');
    }
  });

  describe('insurance edge cases', () => {
    it('accepts insurance and records half-wager side bet', () => {
      const session = insuranceSession(card(7, 'clubs'), [card('Q'), card(9)]);
      const result = applyAction(session, 'learner', 'insurance-accept', createRng(1));
      expect(result.seats[0].hands[0].insuranceWager).toBe(10);
      expect(result.phase).toBe('player-turn');
    });

    it('declines insurance and proceeds to player turn', () => {
      const session = insuranceSession(card(7, 'clubs'), [card('Q'), card(9)]);
      const result = applyAction(session, 'learner', 'insurance-decline', createRng(1));
      expect(result.seats[0].hands[0].insuranceWager).toBeUndefined();
      expect(result.phase).toBe('player-turn');
    });

    it('settles immediately when dealer has blackjack and insurance pays', () => {
      const session = insuranceSession(card('K', 'clubs'), [card('Q'), card(9)]);
      const result = applyAction(session, 'learner', 'insurance-accept', createRng(1));
      expect(result.phase).toBe('settled');
      expect(result.balance).toBe(1000);
    });

    it('pays blackjack when both player and dealer have blackjack', () => {
      const session = insuranceSession(card('K', 'clubs'), [card('A'), card('K')]);
      const result = applyAction(session, 'learner', 'insurance-decline', createRng(1));
      expect(result.phase).toBe('settled');
      expect(result.balance).toBe(1050);
    });
  });

  it('settleHand adjusts balance for busts and wins', () => {
    let session = baseSession();
    session = {
      ...session,
      phase: 'dealer-turn',
      dealerCards: [card(10), card(7)],
      seats: [
        {
          id: 'learner',
          isLearner: true,
          dogBreed: 'learner-dog',
          hands: [
            {
              cards: [card(10), card(9)],
              wager: 20,
              status: 'stood',
              isSplit: false,
              ownerSeatId: 'learner',
            },
          ],
        },
      ],
      balance: 1000,
    };

    const settled = settleHand(session);
    expect(settled.balance).toBe(1020);
    expect(settled.phase).toBe('settled');
    expect(settled.handsPlayed).toBe(1);
  });
});
