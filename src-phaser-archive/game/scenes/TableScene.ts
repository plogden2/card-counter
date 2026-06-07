import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '../config';
import type { GameController } from '../controllers/GameController';
import type { HandAction } from '@/domain/blackjack';

const DOG_COLORS = ['#e57373', '#64b5f6', '#81c784', '#ffb74d', '#ba68c8', '#4dd0e1'];

export class TableScene extends Phaser.Scene {
  private controller!: GameController;
  private hudText?: Phaser.GameObjects.Text;
  private coachingText?: Phaser.GameObjects.Text;
  private actionButtons: Phaser.GameObjects.Text[] = [];
  private dogSprites: Phaser.GameObjects.GameObject[] = [];
  private showingRecovery = false;

  constructor() {
    super({ key: 'TableScene' });
  }

  create(): void {
    this.controller = this.registry.get('controller');
    this.drawTable();
    this.createHud();
    this.createActionButtons();
    this.renderDogs();
    this.setupKeyboard();
    this.subscribeEvents();

    if (this.controller.hasMidHandSnapshot() && !this.showingRecovery) {
      this.showRecoveryDialog();
    } else {
      this.refreshHud();
    }
  }

  private drawTable(): void {
    this.add.ellipse(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 40, 900, 400, 0x0d3d1a);
    this.add.ellipse(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 40, 860, 360, 0x1b5e20);

    this.add
      .text(GAME_WIDTH / 2, 80, 'Dealer', {
        fontSize: '20px',
        color: '#ffffff',
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5);
  }

  private createHud(): void {
    this.hudText = this.add.text(20, 20, '', {
      fontSize: '16px',
      color: '#ffffff',
      fontFamily: 'Arial, sans-serif',
      lineSpacing: 6,
    });

    this.coachingText = this.add.text(20, GAME_HEIGHT - 120, '', {
      fontSize: '14px',
      color: '#fff9c4',
      fontFamily: 'Arial, sans-serif',
      wordWrap: { width: GAME_WIDTH - 40 },
    });
  }

  private createActionButtons(): void {
    const actions: { label: string; action: HandAction | 'deal' | 'continue' | 'reset' | 'home' | 'analytics' }[] = [
      { label: 'Bet $25', action: 'place-bet' },
      { label: 'Deal', action: 'deal' },
      { label: 'Hit', action: 'hit' },
      { label: 'Stand', action: 'stand' },
      { label: 'Double', action: 'double' },
      { label: 'Insure', action: 'insurance-accept' },
      { label: 'Decline Ins.', action: 'insurance-decline' },
      { label: 'Next Hand', action: 'continue' },
      { label: 'Graphs', action: 'analytics' },
      { label: 'Reset $', action: 'reset' },
      { label: 'Home', action: 'home' },
    ];

    let x = 20;
    const y = GAME_HEIGHT - 60;
    for (const { label, action } of actions) {
      const btn = this.add
        .text(x, y, label, {
          fontSize: '13px',
          color: '#ffffff',
          backgroundColor: '#37474f',
          padding: { x: 6, y: 4 },
          fontFamily: 'Arial, sans-serif',
        })
        .setInteractive({ useHandCursor: true });
      btn.on('pointerdown', () => this.handleAction(action));
      this.actionButtons.push(btn);
      x += btn.width + 8;
    }
  }

  private renderDogs(): void {
    const session = this.controller.getSession();
    if (!session) return;

    this.dogSprites.forEach((s) => s.destroy());
    this.dogSprites = [];

    const seats = session.seats;
    const spacing = 700 / Math.max(seats.length, 1);
    const startX = GAME_WIDTH / 2 - (spacing * (seats.length - 1)) / 2;

    seats.forEach((seat, i) => {
      const x = startX + i * spacing;
      const y = GAME_HEIGHT / 2 + 120;
      const color = seat.isLearner ? 0xffd54f : parseInt(DOG_COLORS[i % DOG_COLORS.length].slice(1), 16);

      const body = this.add.rectangle(x, y, 60, 80, color);
      const head = this.add.circle(x, y - 50, 25, color);
      const ear1 = this.add.triangle(x - 18, y - 65, 0, 20, 15, 0, 30, 20, color);
      const ear2 = this.add.triangle(x + 18, y - 65, 0, 20, 15, 0, 30, 20, color);

      const label = this.add
        .text(x, y + 55, seat.isLearner ? 'You' : seat.dogBreed, {
          fontSize: '12px',
          color: '#ffffff',
          fontFamily: 'Arial, sans-serif',
        })
        .setOrigin(0.5);

      this.dogSprites.push(body, head, ear1, ear2, label);
      this.animateDeal(body, x, y);
    });
  }

  private animateDeal(sprite: Phaser.GameObjects.Rectangle, x: number, y: number): void {
    const duration = this.controller.getTweenDuration(300);
    if (duration === 0) return;
    sprite.setAlpha(0);
    sprite.setPosition(x, y + 40);
    this.tweens.add({
      targets: sprite,
      alpha: 1,
      y,
      duration,
      ease: 'Power2',
    });
  }

  private setupKeyboard(): void {
    const keyMap: Record<string, HandAction | 'deal' | 'continue'> = {
      Enter: 'place-bet',
      KeyH: 'hit',
      KeyS: 'stand',
      KeyD: 'double',
      KeyP: 'split',
      KeyI: 'insurance-accept',
      KeyN: 'insurance-decline',
      Space: 'continue',
    };

    this.input.keyboard?.on('keydown', (event: KeyboardEvent) => {
      const action = keyMap[event.code];
      if (action) {
        event.preventDefault();
        if (action === 'place-bet') {
          this.controller.placeBet(25);
          this.controller.deal();
        } else if (action === 'continue') {
          this.controller.continueToNextHand();
          this.refreshHud();
        } else if (action !== 'deal') {
          this.controller.applyAction(action);
          this.refreshHud();
        }
      }
    });
  }

  private subscribeEvents(): void {
    this.controller.events.on('count:updated', () => this.refreshHud());
    this.controller.events.on('coaching:message', (msg) => {
      this.coachingText?.setText(msg.text);
    });
    this.controller.events.on('hand:settled', () => this.refreshHud());
  }

  private handleAction(action: HandAction | 'deal' | 'continue' | 'reset' | 'home' | 'analytics'): void {
    switch (action) {
      case 'place-bet':
        this.controller.placeBet(25);
        break;
      case 'deal':
        this.controller.placeBet(25);
        this.controller.deal();
        this.renderDogs();
        break;
      case 'continue':
        this.controller.continueToNextHand();
        break;
      case 'reset':
        this.showResetDialog();
        return;
      case 'home':
        this.scene.start('HomeScene');
        return;
      case 'analytics':
        this.controller.toggleAnalytics();
        return;
      default:
        this.controller.applyAction(action);
    }
    this.refreshHud();
  }

  private refreshHud(): void {
    const session = this.controller.getSession();
    const profile = this.controller.getProfile();
    if (!session || !this.hudText) return;

    const learnerHand = session.seats.find((s) => s.isLearner)?.hands[0];
    const cards = learnerHand?.cards.map((c) => `${c.rank}${c.suit[0]}`).join(', ') ?? '—';
    const dealerUp = session.dealerCards[0]
      ? `${session.dealerCards[0].rank}${session.dealerCards[0].suit[0]}`
      : '—';

    this.hudText.setText([
      `Balance: $${session.balance}`,
      `RC: ${session.countState.runningCount}  TC: ${session.countState.trueCount}`,
      `Phase: ${session.phase}`,
      `Your cards: ${cards}`,
      `Dealer up: ${dealerUp}`,
      `Hands played: ${session.handsPlayed}`,
      `Sound: ${profile.soundEnabled ? 'on' : 'off'}`,
    ].join('\n'));
  }

  private showRecoveryDialog(): void {
    this.showingRecovery = true;
    const overlay = this.add.rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, 500, 200, 0x000000, 0.85);

    this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 - 50, 'Resume interrupted hand?', {
        fontSize: '22px',
        color: '#ffffff',
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5);

    const resume = this.add
      .text(GAME_WIDTH / 2 - 80, GAME_HEIGHT / 2 + 30, 'Resume', {
        fontSize: '20px',
        color: '#ffffff',
        backgroundColor: '#2e7d32',
        padding: { x: 12, y: 6 },
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true });

    const forfeit = this.add
      .text(GAME_WIDTH / 2 + 80, GAME_HEIGHT / 2 + 30, 'Forfeit', {
        fontSize: '20px',
        color: '#ffffff',
        backgroundColor: '#c62828',
        padding: { x: 12, y: 6 },
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true });

    resume.on('pointerdown', () => {
      this.controller.resumeMidHand();
      overlay.destroy();
      resume.destroy();
      forfeit.destroy();
      this.showingRecovery = false;
      this.refreshHud();
    });

    forfeit.on('pointerdown', () => {
      this.controller.forfeitMidHand();
      overlay.destroy();
      resume.destroy();
      forfeit.destroy();
      this.showingRecovery = false;
      this.refreshHud();
    });
  }

  private showResetDialog(): void {
    const overlay = this.add.rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, 400, 160, 0x000000, 0.85);

    this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 - 40, 'Reset bankroll to $1,000?', {
        fontSize: '20px',
        color: '#ffffff',
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5);

    const confirm = this.add
      .text(GAME_WIDTH / 2 - 70, GAME_HEIGHT / 2 + 30, 'Confirm', {
        fontSize: '18px',
        color: '#ffffff',
        backgroundColor: '#2e7d32',
        padding: { x: 10, y: 5 },
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true });

    const cancel = this.add
      .text(GAME_WIDTH / 2 + 70, GAME_HEIGHT / 2 + 30, 'Cancel', {
        fontSize: '18px',
        color: '#ffffff',
        backgroundColor: '#455a64',
        padding: { x: 10, y: 5 },
        fontFamily: 'Arial, sans-serif',
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true });

    confirm.on('pointerdown', () => {
      this.controller.resetBankrollConfirmed();
      overlay.destroy();
      confirm.destroy();
      cancel.destroy();
      this.refreshHud();
    });

    cancel.on('pointerdown', () => {
      overlay.destroy();
      confirm.destroy();
      cancel.destroy();
    });
  }
}
