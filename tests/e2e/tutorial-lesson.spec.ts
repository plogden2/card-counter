import { test, expect } from '@playwright/test';
import {
  waitForGame,
  clickPhaserText,
  waitForScene,
  getSessionSnapshot,
  settleCurrentHand,
} from './helpers/game';

test.describe('tutorial lesson', () => {
  test('guided L1 lesson flow through play hand', async ({ page }) => {
    await waitForGame(page);

    await clickPhaserText(page, 'Tutorial');
    await waitForScene(page, 'TutorialScene');

    const lessonText = await page.evaluate(() => {
      const game = window.__CARD_COUNTER__?.game;
      const scene = game?.scene.getScenes(true)[0];
      const texts = scene?.children?.list?.filter((c) => c.type === 'Text') ?? [];
      return texts.map((t) => t.text as string).join('\n');
    });
    expect(lessonText).toContain('Lesson L1');
    expect(lessonText).toMatch(/Hi-Lo|\+1/i);

    await clickPhaserText(page, 'Next Step');
    const stepAfterAdvance = await page.evaluate(() => {
      const ctrl = window.__CARD_COUNTER__?.controller as {
        getTutorialProgress?: () => { currentStep: number };
      };
      return ctrl?.getTutorialProgress?.()?.currentStep;
    });
    expect(stepAfterAdvance).toBeGreaterThan(0);

    await clickPhaserText(page, 'Play Hand');
    await waitForScene(page, 'TableScene');

    const session = await getSessionSnapshot(page);
    expect(session?.phase).toBe('betting');

    await clickPhaserText(page, 'Deal');
    const afterDeal = await getSessionSnapshot(page);
    expect(afterDeal?.phase).toMatch(/insurance|player-turn/);

    await settleCurrentHand(page);
    const settled = await getSessionSnapshot(page);
    expect(settled?.phase).toBe('settled');
    expect(settled?.handsPlayed).toBe(1);
  });
});
