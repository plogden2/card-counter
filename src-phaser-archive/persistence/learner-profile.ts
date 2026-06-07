import type { BetModelId } from '@/domain/bet-models';
import type { GameMode } from '@/domain/session';
import { STARTING_BANKROLL } from '@/domain/table-config';

export interface LearnerProfile {
  schemaVersion: 1;
  balance: number;
  selectedBetModel: BetModelId;
  lastMode?: GameMode;
  soundEnabled: boolean;
  motionReduced: boolean;
  lastSessionAt?: string;
}

const STORAGE_KEY = 'card-counter:learner-profile';

export const DEFAULT_PROFILE: LearnerProfile = {
  schemaVersion: 1,
  balance: STARTING_BANKROLL,
  selectedBetModel: 'spread-table',
  soundEnabled: true,
  motionReduced: false,
};

export function loadProfile(): LearnerProfile {
  if (typeof localStorage === 'undefined') {
    return { ...DEFAULT_PROFILE };
  }
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_PROFILE };
    const parsed = JSON.parse(raw) as LearnerProfile;
    if (parsed.schemaVersion !== 1) {
      return { ...DEFAULT_PROFILE };
    }
    return {
      ...DEFAULT_PROFILE,
      ...parsed,
      schemaVersion: 1,
    };
  } catch {
    return { ...DEFAULT_PROFILE };
  }
}

export function saveProfile(profile: LearnerProfile): void {
  if (typeof localStorage === 'undefined') return;
  const toSave: LearnerProfile = {
    ...profile,
    lastSessionAt: new Date().toISOString(),
  };
  localStorage.setItem(STORAGE_KEY, JSON.stringify(toSave));
}

export function readLastMode(): GameMode | undefined {
  return loadProfile().lastMode;
}

export function writeLastMode(mode: GameMode): void {
  const profile = loadProfile();
  saveProfile({ ...profile, lastMode: mode });
}

export function resetBankroll(): LearnerProfile {
  const profile = loadProfile();
  const updated = { ...profile, balance: STARTING_BANKROLL };
  saveProfile(updated);
  return updated;
}
