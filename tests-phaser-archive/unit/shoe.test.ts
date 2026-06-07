import { describe, it, expect } from 'vitest';
import { createRng } from '@/lib/rng';
import {
  buildShoe,
  draw,
  InsufficientCardsError,
  needsReshuffle,
  onHandSettled,
  reshuffle,
} from '@/domain/shoe';

describe('shoe', () => {
  const rng = createRng(42);

  it('builds a shuffled shoe for the requested deck count', () => {
    const shoe = buildShoe(6, rng, 75);
    expect(shoe.cards).toHaveLength(312);
    expect(shoe.handsDealtSinceShuffle).toBe(0);
    expect(shoe.reshuffleAt).toBe(75);
  });

  it('draws cards from the front of the shoe', () => {
    const shoe = buildShoe(1, createRng(1), 30);
    const firstCard = shoe.cards[0];
    const result = draw(shoe, 1);

    expect(result.cards).toEqual([firstCard]);
    expect(result.shoe.cards).toHaveLength(51);
  });

  it('throws InsufficientCardsError when drawing too many cards', () => {
    const shoe = buildShoe(1, createRng(2), 30);
    expect(() => draw(shoe, 53)).toThrow(InsufficientCardsError);
  });

  it('tracks hands dealt since shuffle', () => {
    const shoe = buildShoe(1, createRng(3), 10);
    const updated = onHandSettled(shoe, 10);
    expect(updated.handsDealtSinceShuffle).toBe(1);
  });

  it('needs reshuffle at hand-count threshold', () => {
    const shoe = {
      cards: Array(100).fill({ suit: 'hearts' as const, rank: 2 as const }),
      handsDealtSinceShuffle: 75,
      reshuffleAt: 75,
    };
    expect(needsReshuffle(shoe)).toBe(true);
  });

  it('needs reshuffle when cards exhausted', () => {
    const shoe = {
      cards: [{ suit: 'hearts' as const, rank: 2 as const }],
      handsDealtSinceShuffle: 0,
      reshuffleAt: 75,
    };
    expect(needsReshuffle(shoe, 2)).toBe(true);
    expect(needsReshuffle(shoe, 1)).toBe(false);
  });

  it('reshuffles with a fresh deck and resets hand counter', () => {
    const shoe = buildShoe(2, createRng(4), 50);
    const dealt = onHandSettled(onHandSettled(shoe, 50), 50);
    const fresh = reshuffle(dealt, 2, createRng(5));

    expect(fresh.cards).toHaveLength(104);
    expect(fresh.handsDealtSinceShuffle).toBe(0);
    expect(fresh.reshuffleAt).toBe(50);
  });

  it('supports shoe exhaustion edge case', () => {
    let shoe = buildShoe(1, createRng(6), 200);
    const { shoe: afterDraw, cards } = draw(shoe, 52);
    shoe = afterDraw;
    expect(cards).toHaveLength(52);
    expect(shoe.cards).toHaveLength(0);
    expect(() => draw(shoe, 1)).toThrow(InsufficientCardsError);
  });
});
