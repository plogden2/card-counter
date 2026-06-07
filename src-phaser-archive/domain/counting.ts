import { hiLoTag, type Card } from './card';

export interface CountState {
  runningCount: number;
  decksRemaining: number;
  trueCount: number;
  cardsSeen: number;
}

export function createCountState(cardsRemaining: number): CountState {
  const decksRemaining = Math.max(cardsRemaining / 52, 0.5);
  return {
    runningCount: 0,
    decksRemaining,
    trueCount: 0,
    cardsSeen: 0,
  };
}

export function trueCount(running: number, decksRemaining: number): number {
  const decks = Math.max(decksRemaining, 0.5);
  return Math.floor(running / decks);
}

export function updateCount(state: CountState, cards: Card[], cardsRemaining: number): CountState {
  let running = state.runningCount;
  for (const card of cards) {
    running += hiLoTag(card.rank);
  }
  const decksRemaining = Math.max(cardsRemaining / 52, 0.5);
  return {
    runningCount: running,
    decksRemaining,
    trueCount: trueCount(running, decksRemaining),
    cardsSeen: state.cardsSeen + cards.length,
  };
}
