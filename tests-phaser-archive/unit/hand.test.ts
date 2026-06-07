import { describe, it, expect } from 'vitest';
import {
  handValue,
  isBlackjack,
  canSplit,
  canDouble,
  type Hand,
} from '@/domain/hand';
import type { Card } from '@/domain/card';

const card = (rank: Card['rank']): Card => ({ suit: 'hearts', rank });

const activeHand = (cards: Card[], overrides: Partial<Hand> = {}): Hand => ({
  cards,
  wager: 10,
  status: 'active',
  isSplit: false,
  ownerSeatId: 'learner',
  ...overrides,
});

describe('hand valuation', () => {
  it('values hard totals', () => {
    expect(handValue([card(10), card(7)])).toEqual({ total: 17, soft: false });
  });

  it('values soft hands with Ace as 11', () => {
    expect(handValue([card('A'), card(6)])).toEqual({ total: 17, soft: true });
  });

  it('downgrades Aces when busting', () => {
    expect(handValue([card('A'), card('A'), card(9)])).toEqual({ total: 21, soft: true });
    expect(handValue([card('A'), card(9), card(5)])).toEqual({ total: 15, soft: false });
  });

  it('handles multiple aces without busting', () => {
    expect(handValue([card('A'), card('A'), card('A')]).total).toBe(13);
  });

  it('detects blackjack on two-card 21', () => {
    expect(isBlackjack([card('A'), card('K')])).toBe(true);
    expect(isBlackjack([card('A'), card(9), card(2)])).toBe(false);
  });

  it('allows split on matching pairs when active', () => {
    expect(canSplit(activeHand([card(8), card(8)]))).toBe(true);
    expect(canSplit(activeHand([card(8), card(8)], { isSplit: true }))).toBe(false);
    expect(canSplit(activeHand([card(8), card(8)], { status: 'stood' }))).toBe(false);
  });

  it('allows double on two-card active hands', () => {
    expect(canDouble(activeHand([card(9), card(2)]))).toBe(true);
    expect(canDouble(activeHand([card(9), card(2), card(10)]))).toBe(false);
    expect(canDouble(activeHand([card(9), card(2)], { doubled: true }))).toBe(false);
  });

  it('bust edge case: hard 22+', () => {
    expect(handValue([card(10), card(9), card(5)]).total).toBe(24);
  });
});
