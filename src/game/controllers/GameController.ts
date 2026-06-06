import { EventBus } from '@/lib/events';
import { createRng, type Rng } from '@/lib/rng';
import {
  createSession,
  dealInitial,
  placeBet,
  applyAction,
  type HandAction,
} from '@/domain/blackjack';
import { needsReshuffle, reshuffle } from '@/domain/shoe';
import { createCountState } from '@/domain/counting';
import { getBetCoaching } from '@/domain/bet-sizing';
import { assessStayOrLeave } from '@/domain/stay-or-leave';
import { maybeJoinOrLeave } from '@/domain/table-dynamics';
import { advanceTutorialStep, createTutorialProgress, type TutorialProgress } from '@/domain/tutorial';
import { getLesson } from '@/tutorial/lessons';
import { estimateAdvantage } from '@/domain/advantage';
import { writeLastMode, loadProfile, saveProfile, resetBankroll, type LearnerProfile } from '@/persistence/learner-profile';
import {
  loadHandSnapshot,
  saveHandSnapshot,
  clearHandSnapshot,
  createSnapshot,
} from '@/persistence/hand-snapshot';
import type { SessionState, GameMode } from '@/domain/session';
import type { BetModelId } from '@/domain/bet-models';
import type { TableConfiguration } from '@/domain/table-config';
import { getTweenDuration } from '@/lib/motion-preference';
import { betCoachingHeadline, stayOrLeaveMessage } from '@/tutorial/coaching-copy';
import { AudioManager } from '../audio/AudioManager';
import { AnalyticsOverlay } from '../scenes/AnalyticsOverlay';

export class GameController {
  readonly events = new EventBus();
  private session: SessionState | null = null;
  private rng: Rng = createRng(42);
  private profile: LearnerProfile;
  private tutorialProgress: TutorialProgress = createTutorialProgress();
  private audio = new AudioManager();
  private analyticsOverlay: AnalyticsOverlay | null = null;
  private preHandSnapshot: SessionState | null = null;

  constructor() {
    this.profile = loadProfile();
    this.audio.setEnabled(this.profile.soundEnabled);
    this.checkMidHandRecovery();
  }

  init(parent: HTMLElement): void {
    this.analyticsOverlay = new AnalyticsOverlay(parent);
  }

  getProfile(): LearnerProfile {
    return this.profile;
  }

  setSoundEnabled(enabled: boolean): void {
    this.profile = { ...this.profile, soundEnabled: enabled };
    saveProfile(this.profile);
    this.audio.setEnabled(enabled);
  }

  setMotionReduced(reduced: boolean): void {
    this.profile = { ...this.profile, motionReduced: reduced };
    saveProfile(this.profile);
  }

  getTweenDuration(baseMs: number): number {
    return getTweenDuration(baseMs, this.profile.motionReduced);
  }

  getSession(): SessionState | null {
    return this.session;
  }

  getTutorialProgress(): TutorialProgress {
    return this.tutorialProgress;
  }

  selectMode(mode: GameMode): void {
    writeLastMode(mode);
    this.profile = { ...this.profile, lastMode: mode };
    saveProfile(this.profile);
    this.events.emit('mode:changed', { mode });
  }

  advanceTutorial(): void {
    this.tutorialProgress = advanceTutorialStep(this.tutorialProgress);
  }

  startTutorialTable(): void {
    const lesson = getLesson(this.tutorialProgress.currentLessonId);
    this.startSession('tutorial', lesson?.presetConfig ?? {}, this.profile.selectedBetModel);
    this.session = {
      ...this.session!,
      tutorialLessonId: this.tutorialProgress.currentLessonId,
      tutorialStep: this.tutorialProgress.currentStep,
    };
  }

  startFreePlay(config: Partial<TableConfiguration> & { betModel?: BetModelId }): void {
    this.startSession('free-play', config, config.betModel ?? this.profile.selectedBetModel);
  }

  private startSession(
    mode: GameMode,
    config: Partial<TableConfiguration>,
    betModel: BetModelId,
  ): void {
    this.session = createSession(mode, config, this.profile.balance, betModel, this.rng);
    this.preHandSnapshot = null;
  }

  placeBet(wager: number): void {
    if (!this.session) return;
    this.session = placeBet(this.session, wager);
    this.audio.play('bet');
  }

  deal(): void {
    if (!this.session) return;
    this.preHandSnapshot = structuredClone(this.session);
    this.session = dealInitial(this.session, this.rng);
    this.events.emit('count:updated', this.session.countState);
    this.persistMidHand();
  }

  applyAction(action: HandAction): void {
    if (!this.session) return;
    const balanceBefore = this.session.balance;
    this.session = applyAction(this.session, 'learner', action, this.rng);
    this.events.emit('count:updated', this.session.countState);

    if (action === 'hit') this.audio.play('hit');
    if (action === 'stand') this.audio.play('stand');

    if (this.session.phase === 'settled') {
      this.onHandSettled(balanceBefore);
    } else {
      this.persistMidHand();
    }
  }

  continueToNextHand(): void {
    if (!this.session) return;
    clearHandSnapshot();

    if (needsReshuffle(this.session.shoe)) {
      const shoe = reshuffle(
        this.session.shoe,
        this.session.tableConfiguration.deckCount,
        this.rng,
      );
      this.session = {
        ...this.session,
        shoe,
        countState: createCountState(shoe.cards.length),
        phase: 'betting',
        seats: this.session.seats.map((s) => ({ ...s, hands: [] })),
        dealerCards: [],
        dealerHoleHidden: true,
        currentWager: 0,
      };
      this.events.emit('shoe:reshuffled', { handIndex: this.session.handsPlayed });
    } else {
      this.session = maybeJoinOrLeave(
        {
          ...this.session,
          phase: 'betting',
          seats: this.session.seats.map((s) => ({ ...s, hands: [] })),
          dealerCards: [],
          dealerHoleHidden: true,
          currentWager: 0,
        },
        this.rng,
      );
    }

    const assessment = assessStayOrLeave(this.session);
    this.session = { ...this.session, lastStayAssessment: assessment, lowAdvantageStreak: assessment.lowAdvantageStreak };
    this.events.emit('stay:assessed', assessment);
    if (assessment.recommendation === 'consider-leaving') {
      this.events.emit('coaching:message', {
        text: stayOrLeaveMessage(assessment),
        type: 'stay',
      });
    }
  }

  private onHandSettled(balanceBefore: number): void {
    if (!this.session) return;
    clearHandSnapshot();

    const analyticsPoint = {
      handIndex: this.session.handsPlayed,
      balance: this.session.balance,
      estimatedAdvantage: estimateAdvantage(this.session.countState.trueCount),
      trueCount: this.session.countState.trueCount,
      betModelId: this.session.currentBetModel,
    };

    this.session = {
      ...this.session,
      analytics: [...this.session.analytics, analyticsPoint],
    };

    this.profile = { ...this.profile, balance: this.session.balance };
    saveProfile(this.profile);

    this.events.emit('hand:settled', analyticsPoint);
    this.analyticsOverlay?.append(analyticsPoint);

    const coaching = getBetCoaching(
      this.session.currentWager,
      this.session.currentBetModel,
      {
        trueCount: this.session.countState.trueCount,
        bankroll: this.session.balance,
        tableMinBet: this.session.tableConfiguration.tableMinBet,
        tableMaxBet: this.session.tableConfiguration.tableMaxBet,
      },
    );
    this.events.emit('coaching:message', {
      text: `${betCoachingHeadline(coaching.classification)}: ${coaching.message}`,
      type: 'bet',
    });

    if (this.session.balance > balanceBefore) this.audio.play('win');
    else if (this.session.balance < balanceBefore) this.audio.play('loss');

    const assessment = assessStayOrLeave(this.session);
    this.session = { ...this.session, lastStayAssessment: assessment, lowAdvantageStreak: assessment.lowAdvantageStreak };
    this.events.emit('stay:assessed', assessment);
  }

  toggleAnalytics(): void {
    if (!this.analyticsOverlay || !this.session) return;
    this.analyticsOverlay.toggle(this.session.analytics);
  }

  resetBankrollConfirmed(): void {
    this.profile = resetBankroll();
    if (this.session) {
      this.session = {
        ...this.session,
        balance: this.profile.balance,
        sessionStartBalance: this.profile.balance,
        analytics: [
          ...this.session.analytics,
          {
            handIndex: this.session.handsPlayed,
            balance: this.profile.balance,
            estimatedAdvantage: 0,
            trueCount: this.session.countState.trueCount,
            betModelId: this.session.currentBetModel,
            annotation: 'bankroll-reset',
          },
        ],
      };
    }
  }

  forfeitMidHand(): void {
    if (this.preHandSnapshot) {
      this.session = structuredClone(this.preHandSnapshot);
    }
    clearHandSnapshot();
  }

  resumeMidHand(): void {
    const snapshot = loadHandSnapshot();
    if (snapshot) {
      this.session = snapshot.sessionState;
    }
  }

  private persistMidHand(): void {
    if (!this.session || this.session.phase === 'betting' || this.session.phase === 'settled') {
      return;
    }
    saveHandSnapshot(
      createSnapshot(this.session, this.session.phase, this.session.activeSeatId ?? 'learner'),
    );
  }

  private checkMidHandRecovery(): void {
    const snapshot = loadHandSnapshot();
    if (snapshot) {
      this.session = snapshot.sessionState;
    }
  }

  hasMidHandSnapshot(): boolean {
    return loadHandSnapshot() !== null;
  }

  registerWithPhaser(registry: { set: (key: string, value: unknown) => void }): void {
    registry.set('controller', this);
  }
}
