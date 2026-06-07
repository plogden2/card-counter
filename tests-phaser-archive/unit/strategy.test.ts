import { describe, it, expect } from 'vitest';
import { basicStrategyAction } from '@/domain/strategy';
import type { Hand } from '@/domain/hand';
import type { Card } from '@/domain/card';

const card = (rank: Card['rank']): Card => ({ suit: 'hearts', rank });

const hand = (cards: Card[]): Hand => ({
  cards,
  wager: 10,
  status: 'active',
  isSplit: false,
  ownerSeatId: 'learner',
});

describe('basic strategy', () => {
  it('stands on hard 17 vs dealer 10', () => {
    expect(basicStrategyAction(hand([card(10), card(7)]), card(10))).toBe('stand');
  });

  it('hits hard 16 vs dealer 10', () => {
    expect(basicStrategyAction(hand([card(10), card(6)]), card(10))).toBe('hit');
  });

  it('doubles hard 11 vs dealer 6', () => {
    expect(basicStrategyAction(hand([card(7), card(4)]), card(6))).toBe('double');
  });

  it('splits Aces and 8s', () => {
    expect(basicStrategyAction(hand([card('A'), card('A')]), card(6))).toBe('split');
    expect(basicStrategyAction(hand([card(8), card(8)]), card(10))).toBe('split');
  });

  it('stands on 10-value pairs', () => {
    expect(basicStrategyAction(hand([card(10), card('K')]), card(6))).toBe('stand');
  });

  it('splits 2s through 7s vs weak dealer cards', () => {
    expect(basicStrategyAction(hand([card(2), card(2)]), card(6))).toBe('split');
    expect(basicStrategyAction(hand([card(6), card(6)]), card(6))).toBe('split');
  });

  it('doubles soft 17 vs dealer 6', () => {
    expect(basicStrategyAction(hand([card('A'), card(6)]), card(6))).toBe('double');
  });

  it('stands soft 19 vs dealer 6', () => {
    expect(basicStrategyAction(hand([card('A'), card(8)]), card(6))).toBe('stand');
  });

  it('hits hard 8 vs any dealer up card', () => {
    expect(basicStrategyAction(hand([card(3), card(5)]), card(2))).toBe('hit');
  });
});
