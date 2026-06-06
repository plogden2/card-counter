import { describe, it, expect, afterEach, vi, beforeEach } from 'vitest';
import { bootControllerHarness, type ControllerHarness } from '../helpers/scene-simulator';
import { mockLocalStorage } from '../helpers/storage';

vi.mock('howler', () => ({
  Howl: class {
    play = vi.fn();
  },
}));

describe('analytics panel (integration)', () => {
  let harness: ControllerHarness | null = null;

  beforeEach(() => {
    mockLocalStorage();
  });

  afterEach(() => {
    harness?.destroy();
    harness = null;
    vi.unstubAllGlobals();
  });

  it('appends analytics series when hand settles', () => {
    harness = bootControllerHarness();
    harness.simulator.clickFreePlay();
    harness.simulator.clickStartTable({ deckCount: 1, initialOtherPlayers: 0 });
    harness.simulator.clickDeal();
    harness.simulator.settleHand();

    const analytics = harness.controller.getSession()?.analytics ?? [];
    expect(analytics).toHaveLength(1);
    expect(analytics[0].handIndex).toBe(1);
    expect(analytics[0].balance).toBeGreaterThan(0);
  });

  it('shows overlay on graphs toggle after settle', () => {
    harness = bootControllerHarness();
    harness.simulator.clickFreePlay();
    harness.simulator.clickStartTable({ deckCount: 1, initialOtherPlayers: 0 });
    harness.simulator.clickDeal();
    harness.simulator.settleHand();

    harness.simulator.clickGraphs();
    const overlay = document.getElementById('analytics-overlay');
    expect((overlay?.style as { display?: string }).display).toBe('block');
    expect(overlay?.querySelectorAll('canvas').length).toBe(2);
  });

  it('accumulates analytics series across multiple hands', () => {
    harness = bootControllerHarness();
    harness.simulator.clickFreePlay();
    harness.simulator.clickStartTable({ deckCount: 1, initialOtherPlayers: 0 });

    for (let i = 0; i < 2; i++) {
      harness.simulator.clickDeal();
      harness.simulator.settleHand();
      harness.simulator.clickContinue();
    }

    expect(harness.controller.getSession()?.analytics).toHaveLength(2);
  });
});
