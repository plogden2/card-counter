import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import {
  DEFAULT_PROFILE,
  loadProfile,
  saveProfile,
  readLastMode,
  writeLastMode,
  resetBankroll,
  type LearnerProfile,
} from '@/persistence/learner-profile';
import { STARTING_BANKROLL } from '@/domain/table-config';
import { mockLocalStorage } from '../helpers/storage';

describe('learner profile / bankroll', () => {
  let storage: ReturnType<typeof mockLocalStorage>;

  beforeEach(() => {
    storage = mockLocalStorage();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('defines schema version 1 defaults', () => {
    expect(DEFAULT_PROFILE.schemaVersion).toBe(1);
    expect(DEFAULT_PROFILE.balance).toBe(STARTING_BANKROLL);
    expect(DEFAULT_PROFILE.selectedBetModel).toBe('spread-table');
    expect(DEFAULT_PROFILE.soundEnabled).toBe(true);
    expect(DEFAULT_PROFILE.motionReduced).toBe(false);
  });

  it('returns defaults when storage is empty', () => {
    const profile = loadProfile();
    expect(profile).toEqual(DEFAULT_PROFILE);
  });

  it('round-trips profile through localStorage', () => {
    const profile: LearnerProfile = {
      ...DEFAULT_PROFILE,
      balance: 750,
      selectedBetModel: 'wonging',
      lastMode: 'free-play',
    };
    saveProfile(profile);
    const loaded = loadProfile();
    expect(loaded.balance).toBe(750);
    expect(loaded.selectedBetModel).toBe('wonging');
    expect(loaded.lastMode).toBe('free-play');
    expect(loaded.lastSessionAt).toBeDefined();
  });

  it('reads and writes lastMode stubs (US0)', () => {
    writeLastMode('tutorial');
    expect(readLastMode()).toBe('tutorial');
    expect(storage.store['card-counter:learner-profile']).toContain('tutorial');
  });

  it('resetBankroll restores starting balance (FR-011)', () => {
    saveProfile({ ...DEFAULT_PROFILE, balance: 250 });
    const updated = resetBankroll();
    expect(updated.balance).toBe(STARTING_BANKROLL);
    expect(loadProfile().balance).toBe(STARTING_BANKROLL);
  });

  it('rejects unknown schema versions', () => {
    storage.store['card-counter:learner-profile'] = JSON.stringify({
      schemaVersion: 99,
      balance: 500,
    });
    expect(loadProfile().balance).toBe(STARTING_BANKROLL);
  });
});
