import { describe, it, expect } from 'vitest';
import {
  NO_GATING,
  routeForMode,
  isModeAccessible,
  parseMode,
} from '@/domain/mode-routing';

describe('mode routing', () => {
  it('enforces no gating (FR-001a)', () => {
    expect(NO_GATING).toBe(true);
    expect(isModeAccessible('tutorial')).toBe(true);
    expect(isModeAccessible('free-play')).toBe(true);
  });

  it('routes tutorial mode to TutorialScene', () => {
    expect(routeForMode('tutorial')).toEqual({
      mode: 'tutorial',
      scene: 'TutorialScene',
    });
  });

  it('routes free-play mode to SetupScene', () => {
    expect(routeForMode('free-play')).toEqual({
      mode: 'free-play',
      scene: 'SetupScene',
    });
  });

  it('parses valid mode strings', () => {
    expect(parseMode('tutorial')).toBe('tutorial');
    expect(parseMode('free-play')).toBe('free-play');
  });

  it('returns null for invalid or missing mode strings', () => {
    expect(parseMode(undefined)).toBeNull();
    expect(parseMode('')).toBeNull();
    expect(parseMode('practice')).toBeNull();
  });
});
