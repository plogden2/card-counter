import { Howl } from 'howler';

export type SoundCategory = 'bet' | 'hit' | 'stand' | 'win' | 'loss';

const SOUND_PATHS: Record<SoundCategory, string> = {
  bet: '/assets/audio/bet.mp3',
  hit: '/assets/audio/hit.mp3',
  stand: '/assets/audio/stand.mp3',
  win: '/assets/audio/win.mp3',
  loss: '/assets/audio/loss.mp3',
};

export class AudioManager {
  private sounds = new Map<SoundCategory, Howl>();
  private enabled = true;

  constructor() {
    for (const [category, src] of Object.entries(SOUND_PATHS)) {
      this.sounds.set(
        category as SoundCategory,
        new Howl({ src: [src], volume: 0.5 }),
      );
    }
  }

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }

  play(category: SoundCategory): void {
    if (!this.enabled) return;
    this.sounds.get(category)?.play();
  }

  mapActionToSound(action: string, outcome?: 'win' | 'loss'): SoundCategory | null {
    if (action === 'place-bet') return 'bet';
    if (action === 'hit') return 'hit';
    if (action === 'stand') return 'stand';
    if (outcome === 'win') return 'win';
    if (outcome === 'loss') return 'loss';
    return null;
  }
}
