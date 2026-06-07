import { test, expect } from '@playwright/test';
import {
  waitForGame,
  clickPhaserText,
  waitForScene,
  getSessionSnapshot,
  settleCurrentHand,
} from './helpers/game';

test.describe('practice table', () => {
  test('configures table, deals, and updates count', async ({ page }) => {
    await waitForGame(page);

    await clickPhaserText(page, 'Free Play');
    await waitForScene(page, 'SetupScene');

    await clickPhaserText(page, 'Start Table');
    await waitForScene(page, 'TableScene');

    const beforeDeal = await getSessionSnapshot(page);
    expect(beforeDeal?.phase).toBe('betting');
    expect(beforeDeal?.runningCount).toBe(0);

    await clickPhaserText(page, 'Deal');
    const afterDeal = await getSessionSnapshot(page);
    expect(afterDeal?.phase).toMatch(/insurance|player-turn/);

    await settleCurrentHand(page);
    const settled = await getSessionSnapshot(page);
    expect(settled?.phase).toBe('settled');
    expect(settled?.handsPlayed).toBeGreaterThanOrEqual(1);
  });

  test('returns home from table', async ({ page }) => {
    await waitForGame(page);
    await clickPhaserText(page, 'Free Play');
    await waitForScene(page, 'SetupScene');
    await clickPhaserText(page, 'Start Table');
    await waitForScene(page, 'TableScene');

    await clickPhaserText(page, 'Home');
    await waitForScene(page, 'HomeScene');
  });
});
