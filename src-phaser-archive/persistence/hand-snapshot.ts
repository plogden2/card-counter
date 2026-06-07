import type { SessionState } from '@/domain/session';
import type { HandPhase } from '@/domain/session';

export interface HandSnapshot {
  sessionState: SessionState;
  phase: HandPhase;
  activeSeatId: string;
  savedAt: string;
}

const STORAGE_KEY = 'card-counter:hand-snapshot';

export function loadHandSnapshot(): HandSnapshot | null {
  if (typeof localStorage === 'undefined') return null;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as HandSnapshot;
    if (!parsed.sessionState || !parsed.phase) return null;
    return parsed;
  } catch {
    return null;
  }
}

export function saveHandSnapshot(snapshot: HandSnapshot): void {
  if (typeof localStorage === 'undefined') return;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(snapshot));
}

export function clearHandSnapshot(): void {
  if (typeof localStorage === 'undefined') return;
  localStorage.removeItem(STORAGE_KEY);
}

export function createSnapshot(
  session: SessionState,
  phase: HandPhase,
  activeSeatId: string,
): HandSnapshot {
  return {
    sessionState: session,
    phase,
    activeSeatId,
    savedAt: new Date().toISOString(),
  };
}
