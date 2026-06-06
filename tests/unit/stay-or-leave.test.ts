import { describe, it, expect } from 'vitest';
import { createRng } from '@/lib/rng';
import { createSession } from '@/domain/blackjack';
import { assessStayOrLeave } from '@/domain/stay-or-leave';
import type { SessionState } from '@/domain/session';

function session(overrides: Partial<SessionState> = {}): SessionState {
  const base = createSession(
    'free-play',
    { deckCount: 6, initialOtherPlayers: 0, handsBeforeReshuffle: 75 },
    1000,
    'spread-table',
    createRng(1),
  );
  return { ...base, ...overrides };
}

describe('stay-or-leave assessment', () => {
  it('recommends staying at favorable counts', () => {
    const result = assessStayOrLeave(
      session({
        countState: { runningCount: 12, decksRemaining: 3, trueCount: 4, cardsSeen: 100 },
        balance: 1100,
        sessionStartBalance: 1000,
      }),
    );
    expect(result.recommendation).toBe('stay');
    expect(result.stayScore).toBeGreaterThan(0.35);
  });

  it('tracks low advantage streak', () => {
    const negative = session({
      countState: { runningCount: -8, decksRemaining: 4, trueCount: -2, cardsSeen: 50 },
      lowAdvantageStreak: 2,
    });
    const result = assessStayOrLeave(negative);
    expect(result.lowAdvantageStreak).toBe(3);
  });

  it('resets low advantage streak when count improves', () => {
    const positive = session({
      countState: { runningCount: 8, decksRemaining: 2, trueCount: 4, cardsSeen: 50 },
      lowAdvantageStreak: 5,
    });
    const result = assessStayOrLeave(positive);
    expect(result.lowAdvantageStreak).toBe(0);
  });

  it('penalizes heavy drawdown below 50% of session start', () => {
    const drawdown = session({
      countState: { runningCount: 2, decksRemaining: 4, trueCount: 0, cardsSeen: 20 },
      balance: 400,
      sessionStartBalance: 1000,
    });
    const result = assessStayOrLeave(drawdown);
    expect(result.factors.some((f) => f.includes('50%'))).toBe(true);
  });

  it('flags proximity to reshuffle', () => {
    const nearShuffle = session({
      shoe: {
        cards: Array(200).fill({ suit: 'hearts' as const, rank: 2 as const }),
        handsDealtSinceShuffle: 70,
        reshuffleAt: 75,
      },
      countState: { runningCount: 1, decksRemaining: 4, trueCount: 0, cardsSeen: 10 },
    });
    const result = assessStayOrLeave(nearShuffle);
    expect(result.factors.some((f) => f.includes('reshuffle'))).toBe(true);
  });

  it('considers recent table dynamics', () => {
    const dynamic = session({
      dynamicsEvents: [
        { type: 'join', seatId: 'dog-1', handIndex: 4 },
        { type: 'leave', seatId: 'dog-2', handIndex: 5 },
      ],
      handsPlayed: 5,
      countState: { runningCount: 0, decksRemaining: 4, trueCount: 0, cardsSeen: 10 },
    });
    const result = assessStayOrLeave(dynamic);
    expect(result.factors.some((f) => f.includes('join/leave'))).toBe(true);
  });

  it('recommends leaving after sustained low advantage', () => {
    const leave = session({
      countState: { runningCount: -10, decksRemaining: 5, trueCount: -2, cardsSeen: 80 },
      lowAdvantageStreak: 3,
      shoe: {
        cards: Array(200).fill({ suit: 'hearts' as const, rank: 2 as const }),
        handsDealtSinceShuffle: 60,
        reshuffleAt: 75,
      },
      balance: 900,
      sessionStartBalance: 1000,
    });
    const result = assessStayOrLeave(leave);
    expect(result.recommendation).toBe('consider-leaving');
    expect(result.factors.length).toBeGreaterThanOrEqual(1);
  });

  it('uses higher worthwhile threshold for wonging model', () => {
    const wonging = session({
      currentBetModel: 'wonging',
      countState: { runningCount: -4, decksRemaining: 4, trueCount: -1, cardsSeen: 10 },
    });
    const result = assessStayOrLeave(wonging);
    expect(result.factors.some((f) => f.includes('Conservative Wonging'))).toBe(true);
  });
});
