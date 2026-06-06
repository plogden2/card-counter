import Phaser from 'phaser';
import { GAME_WIDTH } from '../config';
import { getCurrentStepText } from '@/domain/tutorial';

export class TutorialScene extends Phaser.Scene {
  private stepText?: Phaser.GameObjects.Text;

  constructor() {
    super({ key: 'TutorialScene' });
  }

  create(): void {
    const controller = this.registry.get('controller');
    const progress = controller?.getTutorialProgress?.();

    this.add
      .text(GAME_WIDTH / 2, 60, 'Tutorial', {
        fontSize: '36px',
        color: '#ffffff',
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5);

    const lesson = progress
      ? `Lesson ${progress.currentLessonId}`
      : 'Lesson L1';

    this.add
      .text(GAME_WIDTH / 2, 110, lesson, {
        fontSize: '24px',
        color: '#a5d6a7',
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5);

    this.stepText = this.add
      .text(GAME_WIDTH / 2, 220, getCurrentStepText(progress) || 'Loading lesson...', {
        fontSize: '18px',
        color: '#ffffff',
        fontFamily: 'Arial, sans-serif',
        wordWrap: { width: 700 },
        align: 'center',
      })
      .setOrigin(0.5);

    this.createButton(GAME_WIDTH / 2 - 150, 400, 'Next Step', () => {
      controller?.advanceTutorial?.();
      const updated = controller?.getTutorialProgress?.();
      this.stepText?.setText(getCurrentStepText(updated) || 'Lesson complete!');
    });

    this.createButton(GAME_WIDTH / 2 + 150, 400, 'Play Hand', () => {
      controller?.startTutorialTable?.();
      this.scene.start('TableScene', { fromTutorial: true });
    });

    this.createButton(GAME_WIDTH / 2, 500, 'Home', () => {
      this.scene.start('HomeScene');
    });
  }

  private createButton(x: number, y: number, label: string, onClick: () => void): void {
    const btn = this.add
      .text(x, y, label, {
        fontSize: '22px',
        color: '#ffffff',
        backgroundColor: '#1565c0',
        padding: { x: 16, y: 8 },
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true });
    btn.on('pointerdown', onClick);
  }
}
