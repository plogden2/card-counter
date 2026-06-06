import { getBetModel, type BetModelId } from './bet-models';
import type { WagerContext, BetRecommendation } from './bet-models';

export type BetClassification = 'under' | 'optimal' | 'over';

export interface BetCoachingResult {
  classification: BetClassification;
  message: string;
  recommendation: BetRecommendation;
}

export function getRecommendation(
  modelId: BetModelId,
  ctx: WagerContext,
): BetRecommendation {
  return getBetModel(modelId).recommend(ctx);
}

export function classifyBet(
  wager: number,
  recommendation: BetRecommendation,
): BetClassification {
  if (wager < recommendation.min) return 'under';
  if (wager > recommendation.max) return 'over';
  return 'optimal';
}

export function getBetCoaching(
  wager: number,
  modelId: BetModelId,
  ctx: WagerContext,
): BetCoachingResult {
  const recommendation = getRecommendation(modelId, ctx);
  const classification = classifyBet(wager, recommendation);
  const model = getBetModel(modelId);

  let message: string;
  switch (classification) {
    case 'under':
      message = `You bet $${wager}, below the ${model.name} recommended range ($${recommendation.min}–$${recommendation.max}). Under-betting at positive counts leaves edge on the table.`;
      break;
    case 'over':
      message = `You bet $${wager}, above the ${model.name} recommended range ($${recommendation.min}–$${recommendation.max}). Over-betting increases variance without proportional edge.`;
      break;
    default:
      message = `Your $${wager} bet matches the ${model.name} recommended range. Well sized for TC ${ctx.trueCount}.`;
  }

  if (recommendation.floorApplied) {
    message += ' Table minimum applied — optimal calculation was below the floor.';
  }

  return { classification, message, recommendation };
}
