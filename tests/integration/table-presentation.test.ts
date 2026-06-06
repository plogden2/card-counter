import { describe, it, expect, afterEach, vi, beforeEach } from 'vitest';
import { bootControllerHarness, type ControllerHarness } from '../helpers/scene-simulator';
import { mockLocalStorage } from '../helpers/storage';

vi.mock('howler', () => ({
  Howl: class {
    play = vi.fn();
  },
}));

describe('table presentation (integration)', () => {
  let harness: ControllerHarness | null = null;

  beforeEach(() => {
    mockLocalStorage();
  });

  afterEach(() => {
    harness?.destroy();
    harness = null;
    vi.unstubAllGlobals();
  });

  it('exposes animation duration hooks on hand events', () => {
    harness = bootControllerHarness();
    harness.simulator.clickFreePlay();
    harness.simulator.clickStartTable({ deckCount: 1, initialOtherPlayers: 0 });

    const normalDuration = harness.controller.getTweenDuration(300);
    expect(normalDuration).toBe(300);

    harness.controller.setMotionReduced(true);
    expect(harness.controller.getTweenDuration(300)).toBe(0);
  });

  it('skips animation duration when reduced motion is enabled', () => {
    harness = bootControllerHarness();
    harness.controller.setMotionReduced(true);
    harness.simulator.clickFreePlay();
    harness.simulator.clickStartTable({ deckCount: 1, initialOtherPlayers: 0 });

    expect(harness.controller.getTweenDuration(300)).toBe(0);
  });

  it('emits hand lifecycle events used by table presentation', () => {
    harness = bootControllerHarness();
    harness.simulator.clickFreePlay();
    harness.simulator.clickStartTable({ deckCount: 6, initialOtherPlayers: 3 });

    const events: string[] = [];
    harness.controller.events.on('count:updated', () => events.push('count'));
    harness.controller.events.on('hand:settled', () => events.push('settled'));

    harness.simulator.clickDeal();
    harness.simulator.settleHand();

    expect(events).toContain('count');
    expect(events).toContain('settled');

    const session = harness.controller.getSession();
    expect(session?.seats.some((s) => s.isLearner)).toBe(true);
    expect(session?.seats.some((s) => !s.isLearner)).toBe(true);
  });
});
