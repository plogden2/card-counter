import { normalizedAdvantage } from './advantage';
import { getBetModel } from './bet-models';
import type { SessionState } from './session';

export interface StayOrLeaveAssessment {
  stayScore: number;
  recommendation: 'stay' | 'consider-leaving';
  factors: string[];
  lowAdvantageStreak: number;
}

export function assessStayOrLeave(session: SessionState): StayOrLeaveAssessment {
  const model = getBetModel(session.currentBetModel);
  const tc = session.countState.trueCount;
  const worthwhileThreshold = session.currentBetModel === 'wonging' ? 1 : 0;

  const advNorm = normalizedAdvantage(tc, worthwhileThreshold);
  const handsUntilReshuffle = session.shoe.reshuffleAt - session.shoe.handsDealtSinceShuffle;
  const reshuffleProximity =
    handsUntilReshuffle <= session.shoe.reshuffleAt * 0.2 ? 0.2 : 1;

  const recentDynamics = session.dynamicsEvents.filter(
    (e) => e.handIndex >= session.handsPlayed - 3,
  );
  const occupancyFactor = recentDynamics.length > 0 ? 0.7 : 1;

  const drawdownRatio = session.balance / session.sessionStartBalance;
  const drawdownPenalty = drawdownRatio < 0.5 ? 0.4 : 0;

  const stayScore =
    0.4 * advNorm +
    0.25 * reshuffleProximity +
    0.2 * occupancyFactor -
    0.15 * drawdownPenalty;

  const factors: string[] = [];
  if (advNorm < 0.35) {
    factors.push(`True count ${tc} yields low estimated advantage under ${model.name}`);
  }
  if (reshuffleProximity < 0.5) {
    factors.push(`Only ${handsUntilReshuffle} hands until next reshuffle`);
  }
  if (recentDynamics.length > 0) {
    factors.push('Recent player join/leave changes table pace');
  }
  if (drawdownPenalty > 0) {
    factors.push('Balance below 50% of session start — bankroll protection');
  }

  let lowAdvantageStreak = session.lowAdvantageStreak;
  if (advNorm < 0.35) {
    lowAdvantageStreak++;
  } else {
    lowAdvantageStreak = 0;
  }

  const immediateAfterReshuffle =
    session.shoe.handsDealtSinceShuffle === 0 && Math.abs(tc) <= 1;

  const shouldLeave =
    (stayScore < 0.35 && lowAdvantageStreak >= 3) ||
    (immediateAfterReshuffle && stayScore < 0.4);

  const recommendation = shouldLeave ? 'consider-leaving' : 'stay';

  if (recommendation === 'consider-leaving' && factors.length < 2) {
    factors.push('Composite stay score below worthwhile threshold');
    factors.push(`Current true count: ${tc}`);
  }

  return {
    stayScore,
    recommendation,
    factors,
    lowAdvantageStreak,
  };
}
