import { describe, it, expect, vi } from 'vitest';
import { AudioManager } from '@/game/audio/AudioManager';

const playMock = vi.fn();

vi.mock('howler', () => ({
  Howl: class {
    play = playMock;
  },
}));

describe('audio cues (functional)', () => {
  it('maps player actions to sound categories', () => {
    const audio = new AudioManager();
    expect(audio.mapActionToSound('place-bet')).toBe('bet');
    expect(audio.mapActionToSound('hit')).toBe('hit');
    expect(audio.mapActionToSound('stand')).toBe('stand');
    expect(audio.mapActionToSound('unknown')).toBeNull();
    expect(audio.mapActionToSound('settle', 'win')).toBe('win');
    expect(audio.mapActionToSound('settle', 'loss')).toBe('loss');
  });

  it('plays sounds when enabled', () => {
    playMock.mockClear();
    const audio = new AudioManager();
    audio.setEnabled(true);
    audio.play('bet');
    expect(playMock).toHaveBeenCalled();
  });

  it('suppresses sounds when muted mid-session', () => {
    playMock.mockClear();
    const audio = new AudioManager();
    audio.setEnabled(false);
    audio.play('hit');
    audio.play('win');
    expect(playMock).not.toHaveBeenCalled();
  });

  it('re-enables sounds after unmuting', () => {
    playMock.mockClear();
    const audio = new AudioManager();
    audio.setEnabled(false);
    audio.play('stand');
    audio.setEnabled(true);
    audio.play('stand');
    expect(playMock).toHaveBeenCalledOnce();
  });
});
