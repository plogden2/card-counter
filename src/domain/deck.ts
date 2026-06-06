import { createDeck, type Card } from './card';
import { shuffle, type Rng } from '@/lib/rng';

export function buildDecks(deckCount: number): Card[] {
  if (deckCount < 1 || deckCount > 6) {
    throw new RangeError('deckCount must be between 1 and 6');
  }
  const cards: Card[] = [];
  for (let i = 0; i < deckCount; i++) {
    cards.push(...createDeck());
  }
  return cards;
}

export function shuffleDecks(deckCount: number, rng: Rng): Card[] {
  return shuffle(buildDecks(deckCount), rng);
}
