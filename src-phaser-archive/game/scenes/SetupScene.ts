import Phaser from 'phaser';
import { GAME_WIDTH } from '../config';
import { listBetModels } from '@/domain/bet-models';

export class SetupScene extends Phaser.Scene {
  private deckCount = 6;
  private otherPlayers = 3;
  private handsBeforeReshuffle = 75;
  private selectedModel = 'spread-table';

  constructor() {
    super({ key: 'SetupScene' });
  }

  create(data?: { selectedModel?: string }): void {
    const controller = this.registry.get('controller');
    const profile = controller?.getProfile?.();
    if (data?.selectedModel) {
      this.selectedModel = data.selectedModel;
    } else if (profile) {
      this.selectedModel = profile.selectedBetModel;
    }

    this.add
      .text(GAME_WIDTH / 2, 50, 'Free Play Setup', {
        fontSize: '32px',
        color: '#ffffff',
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5);

    this.addConfigRow(120, 'Decks (1-6)', () => `${this.deckCount}`, -1, 1);
    this.addConfigRow(170, 'Other Players (0-5)', () => `${this.otherPlayers}`, -1, 1);
    this.addConfigRow(220, 'Hands Before Reshuffle', () => `${this.handsBeforeReshuffle}`, -10, 10);

    this.add
      .text(100, 280, 'Bet Model:', {
        fontSize: '18px',
        color: '#ffffff',
        fontFamily: 'Arial, sans-serif',
      });

    let y = 310;
    for (const model of listBetModels()) {
      const selected = model.id === this.selectedModel;
      const btn = this.add
        .text(120, y, `${selected ? '● ' : '○ '}${model.name}`, {
          fontSize: '16px',
          color: selected ? '#ffeb3b' : '#ffffff',
          fontFamily: 'Arial, sans-serif',
        })
        .setInteractive({ useHandCursor: true });
      btn.on('pointerdown', () => {
        this.selectedModel = model.id;
        this.scene.restart({ selectedModel: model.id });
      });
      y += 28;
    }

    this.createButton(GAME_WIDTH / 2, 520, 'Start Table', () => {
      controller?.startFreePlay?.({
        deckCount: this.deckCount,
        initialOtherPlayers: this.otherPlayers,
        handsBeforeReshuffle: this.handsBeforeReshuffle,
        betModel: this.selectedModel,
      });
      this.scene.start('TableScene');
    });

    this.createButton(GAME_WIDTH / 2, 580, 'Home', () => {
      this.scene.start('HomeScene');
    });
  }

  private addConfigRow(
    y: number,
    label: string,
    getValue: () => string,
    decDelta: number,
    incDelta: number,
  ): void {
    this.add.text(100, y, label, {
      fontSize: '18px',
      color: '#ffffff',
      fontFamily: 'Arial, sans-serif',
    });

    const valueText = this.add.text(500, y, getValue(), {
      fontSize: '18px',
      color: '#ffeb3b',
      fontFamily: 'Arial, sans-serif',
    });

    this.createSmallButton(420, y, '−', () => {
      if (label.includes('Decks')) this.deckCount = Math.max(1, this.deckCount + decDelta);
      else if (label.includes('Players')) this.otherPlayers = Math.max(0, this.otherPlayers + decDelta);
      else this.handsBeforeReshuffle = Math.max(20, this.handsBeforeReshuffle + decDelta);
      valueText.setText(getValue());
    });

    this.createSmallButton(560, y, '+', () => {
      if (label.includes('Decks')) this.deckCount = Math.min(6, this.deckCount + incDelta);
      else if (label.includes('Players')) this.otherPlayers = Math.min(5, this.otherPlayers + incDelta);
      else this.handsBeforeReshuffle = Math.min(200, this.handsBeforeReshuffle + incDelta);
      valueText.setText(getValue());
    });
  }

  private createButton(x: number, y: number, label: string, onClick: () => void): void {
    const btn = this.add
      .text(x, y, label, {
        fontSize: '24px',
        color: '#ffffff',
        backgroundColor: '#2e7d32',
        padding: { x: 20, y: 10 },
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true });
    btn.on('pointerdown', onClick);
  }

  private createSmallButton(x: number, y: number, label: string, onClick: () => void): void {
    const btn = this.add
      .text(x, y, label, {
        fontSize: '20px',
        color: '#ffffff',
        backgroundColor: '#455a64',
        padding: { x: 8, y: 4 },
        fontFamily: 'Arial, sans-serif',
      })
      .setInteractive({ useHandCursor: true });
    btn.on('pointerdown', onClick);
  }
}
