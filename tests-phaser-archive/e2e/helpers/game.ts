import type { Page } from '@playwright/test';

export interface SessionSnapshot {
  phase: string;
  balance: number;
  runningCount: number;
  trueCount: number;
  handsPlayed: number;
}

declare global {
  interface Window {
    __CARD_COUNTER__?: {
      game: import('phaser').Game;
      controller: {
        getSession: () => {
          phase: string;
          balance: number;
          countState: { runningCount: number; trueCount: number };
          handsPlayed: number;
        } | null;
        getProfile: () => { balance: number; lastMode?: string; soundEnabled: boolean };
      };
    };
  }
}

export async function waitForGame(
  page: Page,
  options: { preserveStorage?: boolean } = {},
): Promise<void> {
  await page.goto('/');
  if (!options.preserveStorage) {
    await page.evaluate(() => {
      localStorage.removeItem('card-counter:learner-profile');
      localStorage.removeItem('card-counter:hand-snapshot');
    });
    await page.reload();
  }
  await page.waitForFunction(
    () => window.__CARD_COUNTER__?.game?.isBooted === true,
    undefined,
    { timeout: 15_000 },
  );
  await page.waitForFunction(
    () => {
      const game = window.__CARD_COUNTER__?.game;
      const scenes = game?.scene?.getScenes(true) ?? [];
      return scenes.length > 0 && scenes[0]?.scene?.key === 'HomeScene';
    },
    undefined,
    { timeout: 15_000 },
  );
}

export async function getActiveSceneKey(page: Page): Promise<string | undefined> {
  return page.evaluate(() => {
    const scenes = window.__CARD_COUNTER__?.game?.scene.getScenes(true) ?? [];
    return scenes[0]?.scene?.key;
  });
}

export async function clickPhaserText(page: Page, label: string | RegExp): Promise<boolean> {
  return page.evaluate((matcher) => {
    const game = window.__CARD_COUNTER__?.game;
    if (!game) return false;

    const scenes = game.scene.getScenes(true);
    for (const scene of scenes) {
      const children = scene.children?.list ?? [];
      for (const child of children) {
        if (child.type !== 'Text' || !child.input?.enabled) continue;
        const text = child.text as string;
        const matches =
          typeof matcher === 'string'
            ? text === matcher || text.includes(matcher)
            : new RegExp(matcher.source, matcher.flags).test(text);
        if (matches) {
          child.emit('pointerdown');
          return true;
        }
      }
    }
    return false;
  }, typeof label === 'string' ? label : { source: label.source, flags: label.flags });
}

export async function waitForScene(page: Page, key: string, timeoutMs = 10_000): Promise<void> {
  await page.waitForFunction(
    (sceneKey) => {
      const scenes = window.__CARD_COUNTER__?.game?.scene.getScenes(true) ?? [];
      return scenes[0]?.scene?.key === sceneKey;
    },
    key,
    { timeout: timeoutMs },
  );
}

export async function getSessionSnapshot(page: Page): Promise<SessionSnapshot | null> {
  return page.evaluate(() => {
    const session = window.__CARD_COUNTER__?.controller.getSession();
    if (!session) return null;
    return {
      phase: session.phase,
      balance: session.balance,
      runningCount: session.countState.runningCount,
      trueCount: session.countState.trueCount,
      handsPlayed: session.handsPlayed,
    };
  });
}

export async function settleCurrentHand(page: Page): Promise<void> {
  let session = await getSessionSnapshot(page);
  if (!session) return;

  if (session.phase === 'insurance') {
    await clickPhaserText(page, 'Decline Ins.');
    session = await getSessionSnapshot(page);
  }
  if (session?.phase === 'player-turn') {
    await clickPhaserText(page, 'Stand');
  }
}
