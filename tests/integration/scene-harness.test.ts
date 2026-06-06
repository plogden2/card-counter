import { describe, it, expect, afterEach, vi, beforeEach } from 'vitest';
import { bootControllerHarness, type ControllerHarness } from '../helpers/scene-simulator';
import { mockLocalStorage } from '../helpers/storage';

vi.mock('howler', () => ({
  Howl: class {
    play = vi.fn();
  },
}));

describe('scene harness (integration)', () => {
  let harness: ControllerHarness | null = null;

  beforeEach(() => {
    mockLocalStorage();
  });

  afterEach(() => {
    harness?.destroy();
    harness = null;
    vi.unstubAllGlobals();
  });

  it('boots GameController and registers with Phaser registry', () => {
    harness = bootControllerHarness();

    const registryController = harness.registry.get('controller');
    expect(registryController).toBe(harness.controller);
    expect(harness.simulator.activeScene).toBe('HomeScene');
  });

  it('loads profile defaults on boot', () => {
    harness = bootControllerHarness();

    const profile = harness.controller.getProfile();
    expect(profile.balance).toBe(1000);
    expect(profile.soundEnabled).toBe(true);
  });

  it('initializes analytics overlay container', () => {
    harness = bootControllerHarness();

    const overlay = document.getElementById('analytics-overlay');
    expect(overlay).toBeTruthy();
    const style = overlay?.style as { cssText?: string; display?: string };
    expect(style?.cssText?.includes('display:none') || style?.display === 'none').toBe(true);
  });
});
