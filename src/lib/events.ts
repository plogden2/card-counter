import type { CountState } from '@/domain/counting';
import type { StayOrLeaveAssessment } from '@/domain/stay-or-leave';
import type { TableDynamicsEvent } from '@/domain/table-dynamics';

export interface SessionAnalytics {
  handIndex: number;
  balance: number;
  estimatedAdvantage: number;
  trueCount: number;
  betModelId: string;
  annotation?: string;
}

export type GameEventMap = {
  'count:updated': CountState;
  'hand:settled': SessionAnalytics;
  'stay:assessed': StayOrLeaveAssessment;
  'player:joined': TableDynamicsEvent;
  'player:left': TableDynamicsEvent;
  'shoe:reshuffled': { handIndex: number };
  'coaching:message': { text: string; type: 'bet' | 'stay' | 'info' };
  'mode:changed': { mode: 'tutorial' | 'free-play' };
  'scene:navigate': { scene: string; data?: Record<string, unknown> };
};

export type GameEventName = keyof GameEventMap;

type Listener<T> = (payload: T) => void;

export class EventBus {
  private listeners = new Map<GameEventName, Set<Listener<unknown>>>();

  on<K extends GameEventName>(event: K, listener: Listener<GameEventMap[K]>): () => void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(listener as Listener<unknown>);
    return () => this.off(event, listener);
  }

  off<K extends GameEventName>(event: K, listener: Listener<GameEventMap[K]>): void {
    this.listeners.get(event)?.delete(listener as Listener<unknown>);
  }

  emit<K extends GameEventName>(event: K, payload: GameEventMap[K]): void {
    for (const listener of this.listeners.get(event) ?? []) {
      listener(payload);
    }
  }

  clear(): void {
    this.listeners.clear();
  }
}
