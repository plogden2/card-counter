import { test, expect } from '@playwright/test';
import {
  waitForGame,
  getActiveSceneKey,
  clickPhaserText,
  waitForScene,
} from './helpers/game';

test.describe('launch modes', () => {
  test('shows Tutorial and Free Play on home screen', async ({ page }) => {
    await waitForGame(page);
    expect(await getActiveSceneKey(page)).toBe('HomeScene');

    expect(await clickPhaserText(page, 'Tutorial')).toBe(true);
    await waitForScene(page, 'TutorialScene');

    await clickPhaserText(page, 'Home');
    await waitForScene(page, 'HomeScene');

    expect(await clickPhaserText(page, 'Free Play')).toBe(true);
    await waitForScene(page, 'SetupScene');
  });

  test('persists selected mode in profile', async ({ page }) => {
    await waitForGame(page);

    await clickPhaserText(page, 'Tutorial');
    await waitForScene(page, 'TutorialScene');

    const tutorialMode = await page.evaluate(
      () => window.__CARD_COUNTER__?.controller.getProfile().lastMode,
    );
    expect(tutorialMode).toBe('tutorial');

    await clickPhaserText(page, 'Home');
    await waitForScene(page, 'HomeScene');
    await clickPhaserText(page, 'Free Play');
    await waitForScene(page, 'SetupScene');

    const freePlayMode = await page.evaluate(
      () => window.__CARD_COUNTER__?.controller.getProfile().lastMode,
    );
    expect(freePlayMode).toBe('free-play');
  });
});
