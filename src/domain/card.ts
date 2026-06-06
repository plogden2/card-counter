export type Suit = 'hearts' | 'diamonds' | 'clubs' | 'spades';

export type Rank =
  | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10
  | 'J' | 'Q' | 'K' | 'A';

export interface Card {
  suit: Suit;
  rank: Rank;
}

const SUITS: Suit[] = ['hearts', 'diamonds', 'clubs', 'spades'];
const RANKS: Rank[] = [2, 3, 4, 5, 6, 7, 8, 9, 10, 'J', 'Q', 'K', 'A'];

export function hiLoTag(rank: Rank): -1 | 0 | 1 {
  if (typeof rank === 'number' && rank >= 2 && rank <= 6) return 1;
  if (rank === 7 || rank === 8 || rank === 9) return 0;
  return -1;
}

export function createDeck(): Card[] {
  const cards: Card[] = [];
  for (const suit of SUITS) {
    for (const rank of RANKS) {
      cards.push({ suit, rank });
    }
  }
  return cards;
}

export function cardEquals(a: Card, b: Card): boolean {
  return a.suit === b.suit && a.rank === b.rank;
}

export function rankValue(rank: Rank): number {
  if (typeof rank === 'number') return rank;
  if (rank === 'A') return 11;
  return 10;
}

export function isPair(cards: Card[]): boolean {
  return cards.length === 2 && rankValue(cards[0].rank) === rankValue(cards[1].rank);
}
