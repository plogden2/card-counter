import Phaser from 'phaser';
import { GAME_WIDTH } from '../config';

export class HomeScene extends Phaser.Scene {
  private muteEnabled = true;

  constructor() {
    super({ key: 'HomeScene' });
  }

  create(): void {
    const controller = this.registry.get('controller');
    const profile = controller?.getProfile?.() ?? { soundEnabled: true };

    this.add
      .text(GAME_WIDTH / 2, 120, 'Card Counter', {
        fontSize: '48px',
        color: '#ffffff',
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5);

    this.add
      .text(GAME_WIDTH / 2, 180, 'Blackjack Counting Tutorial', {
        fontSize: '20px',
        color: '#c8e6c9',
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5);

    this.createButton(GAME_WIDTH / 2, 320, 'Tutorial', () => {
      controller?.selectMode('tutorial');
      this.scene.start('TutorialScene');
    });

    this.createButton(GAME_WIDTH / 2, 400, 'Free Play', () => {
      controller?.selectMode('free-play');
      this.scene.start('SetupScene');
    });

    this.muteEnabled = profile.soundEnabled;
    const muteLabel = this.add
      .text(GAME_WIDTH / 2, 500, `[M] Mute: ${this.muteEnabled ? 'On' : 'Off'}`, {
        fontSize: '18px',
        color: '#ffecb3',
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true });

    muteLabel.on('pointerdown', () => this.toggleMute(controller, muteLabel));

    this.input.keyboard?.on('keydown-M', () => this.toggleMute(controller, muteLabel));
  }

  private createButton(x: number, y: number, label: string, onClick: () => void): void {
    const btn = this.add
      .text(x, y, label, {
        fontSize: '28px',
        color: '#ffffff',
        backgroundColor: '#2e7d32',
        padding: { x: 24, y: 12 },
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true });

    btn.on('pointerover', () => btn.setStyle({ backgroundColor: '#388e3c' }));
    btn.on('pointerout', () => btn.setStyle({ backgroundColor: '#2e7d32' }));
    btn.on('pointerdown', onClick);
  }

  private toggleMute(
    controller: { setSoundEnabled?: (v: boolean) => void } | undefined,
    label: Phaser.GameObjects.Text,
  ): void {
    this.muteEnabled = !this.muteEnabled;
    controller?.setSoundEnabled?.(this.muteEnabled);
    label.setText(`[M] Sound: ${this.muteEnabled ? 'On' : 'Off'}`);
  }
}
