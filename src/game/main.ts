import Phaser from 'phaser';
import { gameConfig } from './config';
import { GameController } from './controllers/GameController';

declare global {
  interface Window {
    __CARD_COUNTER__?: {
      game: Phaser.Game;
      controller: GameController;
    };
  }
}

const container = document.getElementById('game-container');
if (!container) {
  throw new Error('Game container element not found');
}

const controller = new GameController();
controller.init(document.body);

const game = new Phaser.Game({
  ...gameConfig,
  parent: container,
});

game.events.once('ready', () => {
  controller.registerWithPhaser(game.registry);
  window.__CARD_COUNTER__ = { game, controller };
});
