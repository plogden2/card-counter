import { rankValue, type Card } from './card';

export type HandStatus = 'active' | 'stood' | 'bust' | 'blackjack' | 'surrendered';

export interface Hand {
  cards: Card[];
  wager: number;
  insuranceWager?: number;
  status: HandStatus;
  isSplit: boolean;
  ownerSeatId: string;
  doubled?: boolean;
}

export interface HandValue {
  total: number;
  soft: boolean;
}

export function handValue(cards: Card[]): HandValue {
  let total = 0;
  let aces = 0;
  for (const card of cards) {
    if (card.rank === 'A') {
      aces++;
      total += 11;
    } else {
      total += rankValue(card.rank);
    }
  }
  while (total > 21 && aces > 0) {
    total -= 10;
    aces--;
  }
  const soft = aces > 0 && total <= 21;
  return { total, soft };
}

export function isBlackjack(cards: Card[]): boolean {
  return cards.length === 2 && handValue(cards).total === 21;
}

export function canSplit(hand: Hand): boolean {
  return (
    hand.cards.length === 2 &&
    !hand.isSplit &&
    rankValue(hand.cards[0].rank) === rankValue(hand.cards[1].rank) &&
    hand.status === 'active'
  );
}

export function canDouble(hand: Hand): boolean {
  return hand.cards.length === 2 && hand.status === 'active' && !hand.doubled;
}
