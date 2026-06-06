import { describe, it, expect } from 'vitest';
import {
  createDeck,
  hiLoTag,
  cardEquals,
  rankValue,
  isPair,
  type Card,
} from '@/domain/card';

describe('Card domain', () => {
  describe('hiLoTag', () => {
    it('tags low cards (2–6) as +1', () => {
      for (const rank of [2, 3, 4, 5, 6] as const) {
        expect(hiLoTag(rank)).toBe(1);
      }
    });

    it('tags neutral cards (7–9) as 0', () => {
      expect(hiLoTag(7)).toBe(0);
      expect(hiLoTag(8)).toBe(0);
      expect(hiLoTag(9)).toBe(0);
    });

    it('tags high cards (10, face, Ace) as −1', () => {
      expect(hiLoTag(10)).toBe(-1);
      expect(hiLoTag('J')).toBe(-1);
      expect(hiLoTag('Q')).toBe(-1);
      expect(hiLoTag('K')).toBe(-1);
      expect(hiLoTag('A')).toBe(-1);
    });
  });

  describe('createDeck', () => {
    it('creates a standard 52-card deck', () => {
      const deck = createDeck();
      expect(deck).toHaveLength(52);
      const suits = new Set(deck.map((c) => c.suit));
      expect(suits.size).toBe(4);
    });
  });

  describe('cardEquals', () => {
    it('matches cards with same rank and suit', () => {
      const a: Card = { suit: 'hearts', rank: 'A' };
      const b: Card = { suit: 'hearts', rank: 'A' };
      expect(cardEquals(a, b)).toBe(true);
    });

    it('rejects cards with different rank or suit', () => {
      expect(cardEquals({ suit: 'hearts', rank: 'A' }, { suit: 'spades', rank: 'A' })).toBe(false);
      expect(cardEquals({ suit: 'hearts', rank: 'A' }, { suit: 'hearts', rank: 'K' })).toBe(false);
    });
  });

  describe('rankValue', () => {
    it('returns numeric rank for number cards', () => {
      expect(rankValue(7)).toBe(7);
    });

    it('returns 10 for face cards and 11 for Ace', () => {
      expect(rankValue('J')).toBe(10);
      expect(rankValue('Q')).toBe(10);
      expect(rankValue('K')).toBe(10);
      expect(rankValue('A')).toBe(11);
    });
  });

  describe('isPair', () => {
    it('detects matching two-card hands', () => {
      const cards: Card[] = [
        { suit: 'hearts', rank: 'K' },
        { suit: 'spades', rank: 'K' },
      ];
      expect(isPair(cards)).toBe(true);
    });

    it('treats 10 and face cards as pairable', () => {
      const cards: Card[] = [
        { suit: 'hearts', rank: 10 },
        { suit: 'spades', rank: 'Q' },
      ];
      expect(isPair(cards)).toBe(true);
    });

    it('rejects non-pairs', () => {
      expect(isPair([{ suit: 'hearts', rank: 5 }, { suit: 'spades', rank: 9 }])).toBe(false);
      expect(isPair([{ suit: 'hearts', rank: 5 }])).toBe(false);
    });
  });
});
