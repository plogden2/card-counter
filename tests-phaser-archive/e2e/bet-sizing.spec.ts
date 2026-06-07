import { test, expect } from '@playwright/test';
import {
  waitForGame,
  clickPhaserText,
  waitForScene,
  getSessionSnapshot,
  settleCurrentHand,
} from './helpers/game';

test.describe('bet sizing', () => {
  test('selects bet model and shows analytics after hand', async ({ page }) => {
    await waitForGame(page);

    await clickPhaserText(page, 'Free Play');
    await waitForScene(page, 'SetupScene');

    const selected = await clickPhaserText(page, /Flat Unit Ramp/);
    expect(selected).toBe(true);
    await waitForScene(page, 'SetupScene');

    await clickPhaserText(page, 'Start Table');
    await waitForScene(page, 'TableScene');

    const session = await page.evaluate(() => {
      const s = window.__CARD_COUNTER__?.controller.getSession();
      return s?.currentBetModel;
    });
    expect(session).toBe('flat-ramp');

    await clickPhaserText(page, 'Deal');
    await settleCurrentHand(page);

    const analytics = await page.evaluate(() => {
      return window.__CARD_COUNTER__?.controller.getSession()?.analytics ?? [];
    });
    expect(analytics.length).toBeGreaterThanOrEqual(1);

    await clickPhaserText(page, 'Graphs');
    const overlayVisible = await page.evaluate(() => {
      const el = document.getElementById('analytics-overlay');
      return el?.style.display === 'block';
    });
    expect(overlayVisible).toBe(true);
  });
});
