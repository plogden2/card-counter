import { test, expect } from '@playwright/test';
import {
  waitForGame,
  clickPhaserText,
  waitForScene,
  getSessionSnapshot,
  settleCurrentHand,
} from './helpers/game';

test.describe('bankroll persistence', () => {
  test('persists balance across page reload', async ({ page }) => {
    await waitForGame(page);
    await clickPhaserText(page, 'Free Play');
    await waitForScene(page, 'SetupScene');
    await clickPhaserText(page, 'Start Table');
    await waitForScene(page, 'TableScene');

    await clickPhaserText(page, 'Deal');
    await settleCurrentHand(page);

    const balanceBeforeReload = await page.evaluate(
      () => window.__CARD_COUNTER__?.controller.getProfile().balance,
    );

    await page.reload();
    await waitForGame(page, { preserveStorage: true });

    const balanceAfterReload = await page.evaluate(
      () => window.__CARD_COUNTER__?.controller.getProfile().balance,
    );
    expect(balanceAfterReload).toBe(balanceBeforeReload);
  });

  test('resets bankroll with confirmation dialog', async ({ page }) => {
    await page.addInitScript(() => {
      localStorage.setItem(
        'card-counter:learner-profile',
        JSON.stringify({
          schemaVersion: 1,
          balance: 420,
          selectedBetModel: 'spread-table',
          soundEnabled: true,
          motionReduced: false,
        }),
      );
    });

    await waitForGame(page, { preserveStorage: true });
    await clickPhaserText(page, 'Free Play');
    await waitForScene(page, 'SetupScene');
    await clickPhaserText(page, 'Start Table');
    await waitForScene(page, 'TableScene');

    await clickPhaserText(page, 'Reset $');
    await clickPhaserText(page, 'Confirm');

    const balance = await page.evaluate(
      () => window.__CARD_COUNTER__?.controller.getProfile().balance,
    );
    expect(balance).toBe(1000);
  });

  test('prompts forfeit or resume on mid-hand snapshot', async ({ page }) => {
    await page.addInitScript(() => {
      const snapshot = {
        sessionState: {
          mode: 'free-play',
          tableConfiguration: {
            deckCount: 1,
            initialOtherPlayers: 0,
            handsBeforeReshuffle: 30,
            tableMinBet: 5,
            tableMaxBet: 500,
          },
          shoe: {
            cards: [],
            handsDealtSinceShuffle: 0,
            reshuffleAt: 30,
          },
          seats: [
            {
              id: 'learner',
              isLearner: true,
              dogBreed: 'learner-dog',
              hands: [
                {
                  cards: [
                    { suit: 'hearts', rank: '9' },
                    { suit: 'clubs', rank: '7' },
                  ],
                  wager: 25,
                  status: 'active',
                  isSplit: false,
                  ownerSeatId: 'learner',
                },
              ],
            },
          ],
          dealerCards: [
            { suit: 'spades', rank: '10' },
            { suit: 'diamonds', rank: '6' },
          ],
          dealerHoleHidden: true,
          countState: { runningCount: 0, trueCount: 0, cardsSeen: 4, decksRemaining: 1 },
          balance: 1000,
          sessionStartBalance: 1000,
          analytics: [],
          currentBetModel: 'spread-table',
          handsPlayed: 0,
          dynamicsEvents: [],
          phase: 'player-turn',
          activeSeatId: 'learner',
          activeHandIndex: 0,
          currentWager: 25,
          lowAdvantageStreak: 0,
        },
        phase: 'player-turn',
        activeSeatId: 'learner',
        savedAt: new Date().toISOString(),
      };
      localStorage.setItem('card-counter:hand-snapshot', JSON.stringify(snapshot));
    });

    await waitForGame(page, { preserveStorage: true });
    await clickPhaserText(page, 'Free Play');
    await waitForScene(page, 'SetupScene');
    await clickPhaserText(page, 'Start Table');
    await waitForScene(page, 'TableScene');

    const dialogVisible = await page.evaluate(() => {
      const game = window.__CARD_COUNTER__?.game;
      const scene = game?.scene.getScenes(true)[0];
      const texts =
        scene?.children?.list
          ?.map((c) => (typeof c.text === 'string' ? c.text : ''))
          .filter(Boolean) ?? [];
      return texts.some((t) => t.includes('Resume interrupted hand'));
    });
    expect(dialogVisible).toBe(true);

    await clickPhaserText(page, 'Forfeit');
    const session = await getSessionSnapshot(page);
    expect(session?.phase).toBe('betting');
  });
});
