import type { GameMode } from './session';

export const NO_GATING = true;

export interface ModeRoute {
  mode: GameMode;
  scene: string;
}

export function routeForMode(mode: GameMode): ModeRoute {
  return mode === 'tutorial'
    ? { mode, scene: 'TutorialScene' }
    : { mode, scene: 'SetupScene' };
}

export function isModeAccessible(_mode: GameMode): boolean {
  return NO_GATING;
}

export function parseMode(value: string | undefined): GameMode | null {
  if (value === 'tutorial' || value === 'free-play') return value;
  return null;
}
