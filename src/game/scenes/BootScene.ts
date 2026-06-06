import Phaser from 'phaser';

export class BootScene extends Phaser.Scene {
  constructor() {
    super({ key: 'BootScene' });
  }

  preload(): void {
    // Placeholder assets loaded in later stories
  }

  create(): void {
    this.scene.start('HomeScene');
  }
}
