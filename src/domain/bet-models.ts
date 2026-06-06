import type { TableConfiguration } from './table-config';

export type BetModelId = 'spread-table' | 'flat-ramp' | 'wonging';

export interface BetRecommendation {
  min: number;
  max: number;
  unitSize: number;
  floorApplied: boolean;
}

export interface WagerContext {
  trueCount: number;
  bankroll: number;
  tableMinBet: number;
  tableMaxBet: number;
}

export interface BetModel {
  id: BetModelId;
  name: string;
  pros: string[];
  cons: string[];
  expectedReturnProjection(table: TableConfiguration): { hourlyEVMin: number; hourlyEVMax: number };
  recommend(ctx: WagerContext): BetRecommendation;
}

function clampBet(amount: number, ctx: WagerContext): BetRecommendation {
  const unitSize = Math.max(5, Math.floor(ctx.bankroll / 100));
  let min = Math.max(ctx.tableMinBet, amount);
  let floorApplied = min > amount;
  let max = Math.min(ctx.tableMaxBet, ctx.bankroll, min * 2);
  if (max < min) max = min;
  return { min, max, unitSize, floorApplied };
}

const spreadTable: BetModel = {
  id: 'spread-table',
  name: 'Spread Table',
  pros: [
    'Maximizes edge at high true counts',
    'Industry-standard Hi-Lo ramp for learning',
    'Scales bets proportionally to advantage',
  ],
  cons: [
    'Higher variance at large spreads',
    'Larger bet jumps may be noticeable',
    'Requires larger bankroll for high counts',
  ],
  expectedReturnProjection() {
    return { hourlyEVMin: 8, hourlyEVMax: 35 };
  },
  recommend(ctx) {
    const units = spreadUnits(ctx.trueCount);
    return clampBet(units * Math.max(5, Math.floor(ctx.bankroll / 100)), ctx);
  },
};

const flatRamp: BetModel = {
  id: 'flat-ramp',
  name: 'Flat Unit Ramp',
  pros: [
    'Simple to learn and remember',
    'Gradual bet increases reduce variance',
    'Good for beginners practicing count-to-bet mapping',
  ],
  cons: [
    'Under-bets at very high true counts',
    'Over-bets at low positive counts',
    'Lower long-term EV than optimal spreads',
  ],
  expectedReturnProjection() {
    return { hourlyEVMin: 4, hourlyEVMax: 18 };
  },
  recommend(ctx) {
    const units = Math.max(1, Math.min(8, Math.floor(ctx.trueCount)));
    return clampBet(units * Math.max(5, Math.floor(ctx.bankroll / 100)), ctx);
  },
};

const wonging: BetModel = {
  id: 'wonging',
  name: 'Conservative Wonging',
  pros: [
    'Minimizes hours at disadvantage',
    'Reduces variance during negative counts',
    'Teaches table-entry discipline',
  ],
  cons: [
    'Misses hands at neutral counts',
    'Requires patience and discipline',
    'Lower hourly volume than continuous play',
  ],
  expectedReturnProjection() {
    return { hourlyEVMin: 6, hourlyEVMax: 22 };
  },
  recommend(ctx) {
    if (ctx.trueCount < 1) {
      return clampBet(ctx.tableMinBet, ctx);
    }
    const units = wongingUnits(ctx.trueCount);
    return clampBet(units * Math.max(5, Math.floor(ctx.bankroll / 100)), ctx);
  },
};

function spreadUnits(tc: number): number {
  if (tc <= 0) return 1;
  if (tc === 1) return 2;
  if (tc === 2) return 4;
  if (tc === 3) return 6;
  return 8;
}

function wongingUnits(tc: number): number {
  if (tc < 1) return 0;
  if (tc === 1) return 1;
  if (tc === 2) return 2;
  if (tc === 3) return 4;
  return 6;
}

const MODELS: Record<BetModelId, BetModel> = {
  'spread-table': spreadTable,
  'flat-ramp': flatRamp,
  wonging: wonging,
};

export function getBetModel(id: BetModelId): BetModel {
  return MODELS[id];
}

export function listBetModels(): BetModel[] {
  return Object.values(MODELS);
}
