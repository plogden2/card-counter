import { describe, it, expect, afterEach, vi, beforeEach } from 'vitest';
import { bootControllerHarness, type ControllerHarness } from '../helpers/scene-simulator';
import { mockLocalStorage } from '../helpers/storage';

vi.mock('howler', () => ({
  Howl: class {
    play = vi.fn();
  },
}));

describe('practice table (integration)', () => {
  let harness: ControllerHarness | null = null;

  beforeEach(() => {
    mockLocalStorage();
  });

  afterEach(() => {
    harness?.destroy();
    harness = null;
    vi.unstubAllGlobals();
  });

  it('applies setup config and deals with count updates', () => {
    harness = bootControllerHarness();
    harness.simulator.clickFreePlay();
    harness.simulator.clickStartTable({ deckCount: 1, initialOtherPlayers: 0 });

    const counts: number[] = [];
    harness.controller.events.on('count:updated', (state) => counts.push(state.runningCount));

    harness.simulator.clickDeal();
    const session = harness.controller.getSession();
    expect(session).toBeTruthy();
    expect(session!.dealerCards.length).toBeGreaterThanOrEqual(1);
    expect(session!.seats[0].hands[0]?.cards.length).toBe(2);
    expect(counts.length).toBeGreaterThan(0);
  });

  it('wires table configuration from setup to session', () => {
    harness = bootControllerHarness();
    harness.simulator.clickFreePlay();
    harness.simulator.clickStartTable({ deckCount: 4, initialOtherPlayers: 2 });

    const session = harness.controller.getSession();
    expect(session?.tableConfiguration.deckCount).toBe(4);
    expect(session?.tableConfiguration.initialOtherPlayers).toBe(2);
    expect(session?.phase).toBe('betting');
  });

  it('completes a hand through stand when in player turn', () => {
    harness = bootControllerHarness();
    harness.simulator.clickFreePlay();
    harness.simulator.clickStartTable({ deckCount: 1, initialOtherPlayers: 0 });

    harness.simulator.clickDeal();
    harness.simulator.settleHand();

    expect(harness.controller.getSession()?.phase).toBe('settled');
    expect(harness.controller.getSession()?.handsPlayed).toBe(1);
  });
});
