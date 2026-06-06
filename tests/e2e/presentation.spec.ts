import { test, expect } from '@playwright/test';
import {
  waitForGame,
  clickPhaserText,
  waitForScene,
} from './helpers/game';

test.describe('presentation', () => {
  test('shows dog characters at table', async ({ page }) => {
    await waitForGame(page);
    await clickPhaserText(page, 'Free Play');
    await waitForScene(page, 'SetupScene');
    await clickPhaserText(page, 'Start Table');
    await waitForScene(page, 'TableScene');

    const labels = await page.evaluate(() => {
      const game = window.__CARD_COUNTER__?.game;
      const scene = game?.scene.getScenes(true)[0];
      return (scene?.children?.list ?? [])
        .filter((c) => c.type === 'Text')
        .map((c) => c.text as string);
    });

    expect(labels).toContain('You');
    expect(labels.some((l) => l.startsWith('breed-'))).toBe(true);
    expect(labels).toContain('Dealer');
  });

  test('toggles sound via mute control on home', async ({ page }) => {
    await waitForGame(page);

    const before = await page.evaluate(
      () => window.__CARD_COUNTER__?.controller.getProfile().soundEnabled,
    );
    expect(before).toBe(true);

    await clickPhaserText(page, /Mute|Sound/);

    const after = await page.evaluate(
      () => window.__CARD_COUNTER__?.controller.getProfile().soundEnabled,
    );
    expect(after).toBe(false);
  });

  test('reduced motion disables deal animations', async ({ page }) => {
    await page.addInitScript(() => {
      localStorage.setItem(
        'card-counter:learner-profile',
        JSON.stringify({
          schemaVersion: 1,
          balance: 1000,
          selectedBetModel: 'spread-table',
          soundEnabled: true,
          motionReduced: true,
        }),
      );
    });

    await waitForGame(page, { preserveStorage: true });
    await clickPhaserText(page, 'Free Play');
    await waitForScene(page, 'SetupScene');
    await clickPhaserText(page, 'Start Table');
    await waitForScene(page, 'TableScene');

    const tweenCount = await page.evaluate(() => {
      const game = window.__CARD_COUNTER__?.game;
      const scene = game?.scene.getScenes(true)[0];
      const before = scene?.tweens?.getTweens?.()?.length ?? 0;
      const dealBtn = scene?.children?.list?.find(
        (c) => c.type === 'Text' && (c.text as string) === 'Deal',
      );
      dealBtn?.emit('pointerdown');
      const after = scene?.tweens?.getTweens?.()?.length ?? 0;
      return { before, after };
    });

    expect(tweenCount.after).toBe(tweenCount.before);
  });
});
