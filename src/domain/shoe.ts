import { shuffleDecks } from './deck';
import type { Card } from './card';
import type { Rng } from '@/lib/rng';

export class InsufficientCardsError extends Error {
  constructor() {
    super('Insufficient cards in shoe');
    this.name = 'InsufficientCardsError';
  }
}

export interface Shoe {
  cards: Card[];
  handsDealtSinceShuffle: number;
  reshuffleAt: number;
}

export function buildShoe(deckCount: number, rng: Rng, reshuffleAt = 75): Shoe {
  return {
    cards: shuffleDecks(deckCount, rng),
    handsDealtSinceShuffle: 0,
    reshuffleAt,
  };
}

export function draw(shoe: Shoe, n: number): { shoe: Shoe; cards: Card[] } {
  if (n > shoe.cards.length) {
    throw new InsufficientCardsError();
  }
  const drawn = shoe.cards.slice(0, n);
  return {
    shoe: { ...shoe, cards: shoe.cards.slice(n) },
    cards: drawn,
  };
}

export function onHandSettled(shoe: Shoe, reshuffleAt: number): Shoe {
  const handsDealtSinceShuffle = shoe.handsDealtSinceShuffle + 1;
  return { ...shoe, handsDealtSinceShuffle, reshuffleAt };
}

export function needsReshuffle(shoe: Shoe, cardsNeeded = 1): boolean {
  return (
    shoe.handsDealtSinceShuffle >= shoe.reshuffleAt ||
    shoe.cards.length < cardsNeeded
  );
}

export function reshuffle(shoe: Shoe, deckCount: number, rng: Rng): Shoe {
  return {
    cards: shuffleDecks(deckCount, rng),
    handsDealtSinceShuffle: 0,
    reshuffleAt: shoe.reshuffleAt,
  };
}
