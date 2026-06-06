import { describe, it, expect, afterEach, vi, beforeEach } from 'vitest';
import { bootControllerHarness, type ControllerHarness } from '../helpers/scene-simulator';
import { mockLocalStorage } from '../helpers/storage';

vi.mock('howler', () => ({
  Howl: class {
    play = vi.fn();
  },
}));

describe('mode switch (integration)', () => {
  let harness: ControllerHarness | null = null;

  beforeEach(() => {
    mockLocalStorage();
  });

  afterEach(() => {
    harness?.destroy();
    harness = null;
    vi.unstubAllGlobals();
  });

  it('navigates home → tutorial → home → free play', () => {
    harness = bootControllerHarness();
    expect(harness.simulator.activeScene).toBe('HomeScene');

    harness.simulator.clickTutorial();
    expect(harness.simulator.activeScene).toBe('TutorialScene');
    expect(harness.controller.getProfile().lastMode).toBe('tutorial');

    harness.simulator.clickHome();
    expect(harness.simulator.activeScene).toBe('HomeScene');

    harness.simulator.clickFreePlay();
    expect(harness.simulator.activeScene).toBe('SetupScene');
    expect(harness.controller.getProfile().lastMode).toBe('free-play');
  });

  it('persists last mode across scene switches', () => {
    harness = bootControllerHarness();

    harness.simulator.clickTutorial();
    harness.simulator.clickHome();
    harness.simulator.clickFreePlay();

    expect(harness.controller.getProfile().lastMode).toBe('free-play');
  });
});
