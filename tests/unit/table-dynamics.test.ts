import { describe, it, expect } from 'vitest';
import { createRng } from '@/lib/rng';
import { createSession } from '@/domain/blackjack';
import { countOtherPlayers, maybeJoinOrLeave } from '@/domain/table-dynamics';

function findJoinSeed(): number {
  for (let seed = 0; seed < 10_000; seed++) {
    const rng = createRng(seed);
    if (rng.next() <= 0.15) return seed;
  }
  throw new Error('no join seed found');
}

describe('table dynamics', () => {
  it('counts other players excluding learner', () => {
    const session = createSession('free-play', { initialOtherPlayers: 3 }, 1000, 'spread-table', createRng(1));
    expect(countOtherPlayers(session.seats)).toBe(3);
  });

  it('does not mutate during active hand phases', () => {
    const session = createSession('free-play', {}, 1000, 'spread-table', createRng(1));
    const midHand = { ...session, phase: 'player-turn' as const };
    const result = maybeJoinOrLeave(midHand, createRng(findJoinSeed()));
    expect(result.seats).toHaveLength(session.seats.length);
    expect(result.dynamicsEvents).toHaveLength(0);
  });

  it('may add a player during betting with favorable RNG', () => {
    const session = createSession(
      'free-play',
      { initialOtherPlayers: 0 },
      1000,
      'spread-table',
      createRng(1),
    );
    const betting = { ...session, phase: 'betting' as const };
    const result = maybeJoinOrLeave(betting, createRng(findJoinSeed()));
    expect(result.seats.length).toBeGreaterThanOrEqual(betting.seats.length);
    if (result.seats.length > betting.seats.length) {
      expect(result.dynamicsEvents.at(-1)?.type).toBe('join');
    }
  });

  it('may remove a player when table is occupied', () => {
    let seed = -1;
    for (let s = 0; s < 10_000; s++) {
      const rng = createRng(s);
      if (rng.next() <= 0.15 && rng.next() <= 0.4) {
        seed = s;
        break;
      }
    }
    expect(seed).toBeGreaterThanOrEqual(0);

    const session = createSession(
      'free-play',
      { initialOtherPlayers: 2 },
      1000,
      'spread-table',
      createRng(1),
    );
    const settled = { ...session, phase: 'settled' as const };
    const result = maybeJoinOrLeave(settled, createRng(seed));
    if (result.seats.length < settled.seats.length) {
      expect(result.dynamicsEvents.at(-1)?.type).toBe('leave');
    }
  });
});
