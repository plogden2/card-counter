import { describe, it, expect } from 'vitest';
import { createCountState, trueCount, updateCount } from '@/domain/counting';
import type { Card } from '@/domain/card';

const card = (rank: Card['rank']): Card => ({ suit: 'hearts', rank });

describe('Hi-Lo counting', () => {
  it('initializes count state from cards remaining', () => {
    const state = createCountState(312);
    expect(state.runningCount).toBe(0);
    expect(state.trueCount).toBe(0);
    expect(state.cardsSeen).toBe(0);
    expect(state.decksRemaining).toBe(6);
  });

  it('floors decks remaining at 0.5 minimum', () => {
    expect(trueCount(5, 0.1)).toBe(10);
    const state = createCountState(10);
    expect(state.decksRemaining).toBe(0.5);
  });

  it('computes true count as floor(running / decks remaining)', () => {
    expect(trueCount(7, 3.5)).toBe(2);
    expect(trueCount(-4, 2)).toBe(-2);
  });

  it('updates running count from dealt cards', () => {
    const initial = createCountState(312);
    const cards: Card[] = [card(5), card('K'), card(3), card(9)];
    const updated = updateCount(initial, cards, 300);

    expect(updated.runningCount).toBe(1);
    expect(updated.cardsSeen).toBe(4);
    expect(updated.trueCount).toBe(Math.floor(updated.runningCount / updated.decksRemaining));
  });

  it('counts only visible cards from multiple seats', () => {
    let state = createCountState(312);
    const seat1 = [card(2), card('A')];
    const seat2 = [card(6), card('Q')];
    const dealerUp = [card(4)];

    state = updateCount(state, [...seat1, ...seat2, ...dealerUp], 300);
    expect(state.runningCount).toBe(1);
    expect(state.cardsSeen).toBe(5);
  });

  it('accumulates count across multiple updates', () => {
    let state = createCountState(312);
    state = updateCount(state, [card(2), card(3)], 308);
    state = updateCount(state, [card('K'), card('A')], 304);

    expect(state.runningCount).toBe(0);
    expect(state.cardsSeen).toBe(4);
  });
});
