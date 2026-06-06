import { GameController } from '@/game/controllers/GameController';
import type { TableConfiguration } from '@/domain/table-config';
import type { BetModelId } from '@/domain/bet-models';
import { routeForMode } from '@/domain/mode-routing';
import { installMinimalDom } from './dom-mock-core';

export interface ControllerHarness {
  controller: GameController;
  simulator: SceneSimulator;
  registry: {
    get: (key: string) => unknown;
    set: (key: string, value: unknown) => void;
  };
  destroy: () => void;
}

export class SceneSimulator {
  activeScene = 'HomeScene';

  constructor(private controller: GameController) {}

  clickTutorial(): void {
    this.controller.selectMode('tutorial');
    this.activeScene = routeForMode('tutorial').scene;
  }

  clickFreePlay(): void {
    this.controller.selectMode('free-play');
    this.activeScene = routeForMode('free-play').scene;
  }

  clickHome(): void {
    this.activeScene = 'HomeScene';
  }

  clickStartTable(
    config: Partial<TableConfiguration> & { betModel?: BetModelId } = {},
  ): void {
    this.controller.startFreePlay({
      deckCount: config.deckCount ?? 6,
      initialOtherPlayers: config.initialOtherPlayers ?? 3,
      handsBeforeReshuffle: config.handsBeforeReshuffle ?? 75,
      betModel: config.betModel,
    });
    this.activeScene = 'TableScene';
  }

  clickPlayTutorialHand(): void {
    this.controller.startTutorialTable();
    this.activeScene = 'TableScene';
  }

  clickDeal(): void {
    this.controller.placeBet(25);
    this.controller.deal();
  }

  clickStand(): void {
    this.controller.applyAction('stand');
  }

  clickDeclineInsurance(): void {
    this.controller.applyAction('insurance-decline');
  }

  clickContinue(): void {
    this.controller.continueToNextHand();
  }

  clickGraphs(): void {
    this.controller.toggleAnalytics();
  }

  clickResetConfirm(): void {
    this.controller.resetBankrollConfirmed();
  }

  shouldShowRecoveryDialog(): boolean {
    return (
      this.activeScene === 'TableScene' &&
      this.controller.hasMidHandSnapshot()
    );
  }

  settleHand(): void {
    const session = this.controller.getSession();
    if (!session) return;
    if (session.phase === 'insurance') this.clickDeclineInsurance();
    if (this.controller.getSession()?.phase === 'player-turn') this.clickStand();
  }
}

export function bootControllerHarness(): ControllerHarness {
  installMinimalDom();

  const controller = new GameController();
  controller.init(document.body);

  const registry = {
    data: new Map<string, unknown>(),
    set(key: string, value: unknown) {
      this.data.set(key, value);
    },
    get(key: string) {
      return this.data.get(key);
    },
  };
  controller.registerWithPhaser(registry);

  return {
    controller,
    simulator: new SceneSimulator(controller),
    registry,
    destroy: () => {
      document.getElementById('analytics-overlay')?.remove();
    },
  };
}
