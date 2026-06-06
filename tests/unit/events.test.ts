import { describe, it, expect, vi } from 'vitest';
import { EventBus } from '@/lib/events';
import type { CountState } from '@/domain/counting';

describe('EventBus', () => {
  it('delivers typed payloads to subscribers', () => {
    const bus = new EventBus();
    const listener = vi.fn();
    const payload: CountState = {
      runningCount: 3,
      decksRemaining: 4,
      trueCount: 0,
      cardsSeen: 12,
    };

    bus.on('count:updated', listener);
    bus.emit('count:updated', payload);

    expect(listener).toHaveBeenCalledOnce();
    expect(listener).toHaveBeenCalledWith(payload);
  });

  it('supports multiple listeners on the same event', () => {
    const bus = new EventBus();
    const a = vi.fn();
    const b = vi.fn();

    bus.on('mode:changed', a);
    bus.on('mode:changed', b);
    bus.emit('mode:changed', { mode: 'tutorial' });

    expect(a).toHaveBeenCalledOnce();
    expect(b).toHaveBeenCalledOnce();
  });

  it('unsubscribes via returned cleanup function', () => {
    const bus = new EventBus();
    const listener = vi.fn();

    const unsubscribe = bus.on('scene:navigate', listener);
    unsubscribe();
    bus.emit('scene:navigate', { scene: 'HomeScene' });

    expect(listener).not.toHaveBeenCalled();
  });

  it('removes listeners via off()', () => {
    const bus = new EventBus();
    const listener = vi.fn();

    bus.on('coaching:message', listener);
    bus.off('coaching:message', listener);
    bus.emit('coaching:message', { text: 'test', type: 'info' });

    expect(listener).not.toHaveBeenCalled();
  });

  it('clear() removes all listeners', () => {
    const bus = new EventBus();
    const listener = vi.fn();

    bus.on('hand:settled', listener);
    bus.clear();
    bus.emit('hand:settled', {
      handIndex: 1,
      balance: 1000,
      estimatedAdvantage: 0.5,
      trueCount: 1,
      betModelId: 'spread-table',
    });

    expect(listener).not.toHaveBeenCalled();
  });

  it('emits stay:assessed with assessment shape', () => {
    const bus = new EventBus();
    const listener = vi.fn();

    bus.on('stay:assessed', listener);
    bus.emit('stay:assessed', {
      stayScore: 0.6,
      recommendation: 'stay',
      factors: [],
      lowAdvantageStreak: 0,
    });

    expect(listener.mock.calls[0][0].recommendation).toBe('stay');
  });
});
