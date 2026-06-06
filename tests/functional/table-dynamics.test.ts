import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { GameController } from '@/game/controllers/GameController';
import { createRng } from '@/lib/rng';
import { maybeJoinOrLeave } from '@/domain/table-dynamics';
import { createSession } from '@/domain/blackjack';
import { mockLocalStorage } from '../helpers/storage';

vi.mock('howler', () => ({
  Howl: class {
    play = vi.fn();
  },
}));

function findDynamicsSeed(): number {
  for (let seed = 0; seed < 10_000; seed++) {
    const rng = createRng(seed);
    if (rng.next() <= 0.15) return seed;
  }
  throw new Error('no dynamics seed');
}

describe('table dynamics events (functional)', () => {
  beforeEach(() => {
    mockLocalStorage();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('records join events when players enter', () => {
    const session = createSession('free-play', { initialOtherPlayers: 0 }, 1000, 'spread-table', createRng(1));
    const betting = { ...session, phase: 'betting' as const };
    const updated = maybeJoinOrLeave(betting, createRng(findDynamicsSeed()));

    if (updated.seats.length > betting.seats.length) {
      const event = updated.dynamicsEvents.at(-1);
      expect(event?.type).toBe('join');
      expect(event?.seatId).toMatch(/^dog-/);
    }
  });

  it('emits stay assessment after continuing to next hand', () => {
    const controller = new GameController();
    const assessments: string[] = [];
    controller.events.on('stay:assessed', (a) => assessments.push(a.recommendation));

    controller.startFreePlay({ deckCount: 1, initialOtherPlayers: 1, handsBeforeReshuffle: 30 });
    controller.placeBet(10);
    controller.deal();
    if (controller.getSession()?.phase === 'insurance') controller.applyAction('insurance-decline');
    if (controller.getSession()?.phase === 'player-turn') controller.applyAction('stand');

    controller.continueToNextHand();
    expect(assessments.length).toBeGreaterThan(0);
    expect(['stay', 'consider-leaving']).toContain(assessments[0]);
  });

  it('may emit stay coaching when leaving is recommended', () => {
    const controller = new GameController();
    const stayMessages: string[] = [];
    controller.events.on('coaching:message', ({ text, type }) => {
      if (type === 'stay') stayMessages.push(text);
    });

    controller.startFreePlay({ deckCount: 1, initialOtherPlayers: 0, handsBeforeReshuffle: 5 });
    for (let i = 0; i < 4; i++) {
      controller.placeBet(10);
      controller.deal();
      if (controller.getSession()?.phase === 'insurance') controller.applyAction('insurance-decline');
      if (controller.getSession()?.phase === 'player-turn') controller.applyAction('stand');
      controller.continueToNextHand();
    }

    const session = controller.getSession();
    expect(session?.lastStayAssessment).toBeDefined();
    if (session?.lastStayAssessment?.recommendation === 'consider-leaving') {
      expect(stayMessages.length).toBeGreaterThan(0);
    }
  });
});
