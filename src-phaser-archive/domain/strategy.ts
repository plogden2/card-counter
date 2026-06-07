import { handValue, type Hand } from './hand';
import type { Card } from './card';

export type StrategyAction = 'hit' | 'stand' | 'double' | 'split';

const HARD: Record<number, Record<number, StrategyAction>> = {
  8: { 2: 'hit', 3: 'hit', 4: 'hit', 5: 'hit', 6: 'hit', 7: 'hit', 8: 'hit', 9: 'hit', 10: 'hit', 11: 'hit' },
  9: { 2: 'hit', 3: 'double', 4: 'double', 5: 'double', 6: 'double', 7: 'hit', 8: 'hit', 9: 'hit', 10: 'hit', 11: 'hit' },
  10: { 2: 'double', 3: 'double', 4: 'double', 5: 'double', 6: 'double', 7: 'double', 8: 'double', 9: 'double', 10: 'hit', 11: 'hit' },
  11: { 2: 'double', 3: 'double', 4: 'double', 5: 'double', 6: 'double', 7: 'double', 8: 'double', 9: 'double', 10: 'double', 11: 'hit' },
  12: { 2: 'hit', 3: 'hit', 4: 'stand', 5: 'stand', 6: 'stand', 7: 'hit', 8: 'hit', 9: 'hit', 10: 'hit', 11: 'hit' },
  13: { 2: 'stand', 3: 'stand', 4: 'stand', 5: 'stand', 6: 'stand', 7: 'hit', 8: 'hit', 9: 'hit', 10: 'hit', 11: 'hit' },
  14: { 2: 'stand', 3: 'stand', 4: 'stand', 5: 'stand', 6: 'stand', 7: 'hit', 8: 'hit', 9: 'hit', 10: 'hit', 11: 'hit' },
  15: { 2: 'stand', 3: 'stand', 4: 'stand', 5: 'stand', 6: 'stand', 7: 'hit', 8: 'hit', 9: 'hit', 10: 'hit', 11: 'hit' },
  16: { 2: 'stand', 3: 'stand', 4: 'stand', 5: 'stand', 6: 'stand', 7: 'hit', 8: 'hit', 9: 'hit', 10: 'hit', 11: 'hit' },
  17: { 2: 'stand', 3: 'stand', 4: 'stand', 5: 'stand', 6: 'stand', 7: 'stand', 8: 'stand', 9: 'stand', 10: 'stand', 11: 'stand' },
};

const SOFT: Record<number, Record<number, StrategyAction>> = {
  13: { 2: 'hit', 3: 'hit', 4: 'hit', 5: 'double', 6: 'double', 7: 'hit', 8: 'hit', 9: 'hit', 10: 'hit', 11: 'hit' },
  14: { 2: 'hit', 3: 'hit', 4: 'hit', 5: 'double', 6: 'double', 7: 'hit', 8: 'hit', 9: 'hit', 10: 'hit', 11: 'hit' },
  15: { 2: 'hit', 3: 'hit', 4: 'double', 5: 'double', 6: 'double', 7: 'hit', 8: 'hit', 9: 'hit', 10: 'hit', 11: 'hit' },
  16: { 2: 'hit', 3: 'hit', 4: 'double', 5: 'double', 6: 'double', 7: 'hit', 8: 'hit', 9: 'hit', 10: 'hit', 11: 'hit' },
  17: { 2: 'hit', 3: 'double', 4: 'double', 5: 'double', 6: 'double', 7: 'hit', 8: 'hit', 9: 'hit', 10: 'hit', 11: 'hit' },
  18: { 2: 'stand', 3: 'double', 4: 'double', 5: 'double', 6: 'double', 7: 'stand', 8: 'stand', 9: 'hit', 10: 'hit', 11: 'hit' },
  19: { 2: 'stand', 3: 'stand', 4: 'stand', 5: 'stand', 6: 'stand', 7: 'stand', 8: 'stand', 9: 'stand', 10: 'stand', 11: 'stand' },
};

function dealerUpValue(upCard: Card): number {
  if (upCard.rank === 'A') return 11;
  if (typeof upCard.rank === 'number') return upCard.rank;
  return 10;
}

export function basicStrategyAction(hand: Hand, dealerUpCard: Card): StrategyAction {
  const { total, soft } = handValue(hand.cards);
  const dealer = dealerUpValue(dealerUpCard);

  if (hand.cards.length === 2 && hand.cards[0].rank === hand.cards[1].rank) {
    const pairRank = hand.cards[0].rank;
    if (pairRank === 'A' || pairRank === 8) return 'split';
    if (pairRank === 10 || pairRank === 'J' || pairRank === 'Q' || pairRank === 'K') return 'stand';
    if (pairRank === 9 && dealer !== 7 && dealer !== 10 && dealer !== 11) return 'split';
    if (pairRank === 7 && dealer <= 7) return 'split';
    if (pairRank === 6 && dealer <= 6) return 'split';
    if (pairRank === 4 && (dealer === 5 || dealer === 6)) return 'split';
    if (pairRank === 3 && dealer <= 7) return 'split';
    if (pairRank === 2 && dealer <= 7) return 'split';
  }

  if (soft && SOFT[total]) {
    return SOFT[total][dealer] ?? 'stand';
  }

  const clamped = Math.max(8, Math.min(17, total));
  return HARD[clamped]?.[dealer] ?? (total >= 17 ? 'stand' : 'hit');
}
