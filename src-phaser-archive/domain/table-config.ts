export interface TableConfiguration {
  deckCount: number;
  initialOtherPlayers: number;
  handsBeforeReshuffle: number;
  tableMinBet: number;
  tableMaxBet: number;
}

export const DEFAULT_TABLE_CONFIG: TableConfiguration = {
  deckCount: 6,
  initialOtherPlayers: 3,
  handsBeforeReshuffle: 75,
  tableMinBet: 5,
  tableMaxBet: 500,
};

export const STARTING_BANKROLL = 1000;

export function validateTableConfig(config: Partial<TableConfiguration>): TableConfiguration {
  const deckCount = clampInt(config.deckCount ?? 6, 1, 6);
  const initialOtherPlayers = clampInt(config.initialOtherPlayers ?? 3, 0, 5);
  const handsBeforeReshuffle = clampInt(config.handsBeforeReshuffle ?? 75, 20, 200);
  return {
    deckCount,
    initialOtherPlayers,
    handsBeforeReshuffle,
    tableMinBet: 5,
    tableMaxBet: 500,
  };
}

function clampInt(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, Math.floor(value)));
}
