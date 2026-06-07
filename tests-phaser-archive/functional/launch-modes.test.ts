import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { GameController } from '@/game/controllers/GameController';
import { routeForMode, isModeAccessible } from '@/domain/mode-routing';
import { mockLocalStorage } from '../helpers/storage';

vi.mock('howler', () => ({
  Howl: class {
    play = vi.fn();
  },
}));

describe('launch modes (functional)', () => {
  let storage: ReturnType<typeof mockLocalStorage>;

  beforeEach(() => {
    storage = mockLocalStorage();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('exposes both modes without gating', () => {
    expect(isModeAccessible('tutorial')).toBe(true);
    expect(isModeAccessible('free-play')).toBe(true);
  });

  it('routes modes to correct entry scenes', () => {
    expect(routeForMode('tutorial').scene).toBe('TutorialScene');
    expect(routeForMode('free-play').scene).toBe('SetupScene');
  });

  it('persists selected mode via controller', () => {
    const controller = new GameController();
    const events: string[] = [];
    controller.events.on('mode:changed', ({ mode }) => events.push(mode));

    controller.selectMode('tutorial');
    expect(events).toContain('tutorial');
    expect(controller.getProfile().lastMode).toBe('tutorial');
    expect(storage.store['card-counter:learner-profile']).toContain('tutorial');

    controller.selectMode('free-play');
    expect(events).toContain('free-play');
    expect(controller.getProfile().lastMode).toBe('free-play');
  });

  it('starts tutorial table with lesson preset config', () => {
    const controller = new GameController();
    controller.selectMode('tutorial');
    controller.startTutorialTable();

    const session = controller.getSession();
    expect(session?.mode).toBe('tutorial');
    expect(session?.tableConfiguration.deckCount).toBe(1);
    expect(session?.tutorialLessonId).toBe('L1');
    expect(session?.phase).toBe('betting');
  });

  it('starts free play with custom configuration', () => {
    const controller = new GameController();
    controller.selectMode('free-play');
    controller.startFreePlay({ deckCount: 4, initialOtherPlayers: 2, betModel: 'flat-ramp' });

    const session = controller.getSession();
    expect(session?.mode).toBe('free-play');
    expect(session?.tableConfiguration.deckCount).toBe(4);
    expect(session?.tableConfiguration.initialOtherPlayers).toBe(2);
    expect(session?.currentBetModel).toBe('flat-ramp');
  });
});
