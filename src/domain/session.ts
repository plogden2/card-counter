import type { CountState } from './counting';
import type { Hand } from './hand';
import type { Shoe } from './shoe';
import type { TableConfiguration } from './table-config';
import type { BetModelId } from './bet-models';
import type { SessionAnalytics } from '@/lib/events';
import type { TableDynamicsEvent } from './table-dynamics';
import type { StayOrLeaveAssessment } from './stay-or-leave';

export type GameMode = 'tutorial' | 'free-play';

export type HandPhase = 'betting' | 'insurance' | 'player-turn' | 'dealer-turn' | 'settled';

export interface Seat {
  id: string;
  isLearner: boolean;
  dogBreed: string;
  hands: Hand[];
}

export interface SessionState {
  mode: GameMode;
  tableConfiguration: TableConfiguration;
  shoe: Shoe;
  seats: Seat[];
  dealerCards: import('./card').Card[];
  dealerHoleHidden: boolean;
  countState: CountState;
  balance: number;
  sessionStartBalance: number;
  analytics: SessionAnalytics[];
  currentBetModel: BetModelId;
  handsPlayed: number;
  dynamicsEvents: TableDynamicsEvent[];
  phase: HandPhase;
  activeSeatId: string | null;
  activeHandIndex: number;
  currentWager: number;
  lastStayAssessment?: StayOrLeaveAssessment;
  lowAdvantageStreak: number;
  tutorialLessonId?: string;
  tutorialStep?: number;
}
