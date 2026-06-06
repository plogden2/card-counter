import type { Rng } from '@/lib/rng';
import type { SessionState } from './session';

export interface TableDynamicsEvent {
  type: 'join' | 'leave';
  seatId: string;
  handIndex: number;
}

export function countOtherPlayers(seats: SessionState['seats']): number {
  return seats.filter((s) => !s.isLearner).length;
}

export function maybeJoinOrLeave(session: SessionState, rng: Rng): SessionState {
  if (session.phase !== 'betting' && session.phase !== 'settled') {
    return session;
  }

  if (rng.next() > 0.15) {
    return session;
  }

  const otherCount = countOtherPlayers(session.seats);
  const shouldJoin = otherCount < 5 && (otherCount === 0 || rng.next() > 0.4);
  const shouldLeave = otherCount > 0 && !shouldJoin;

  if (shouldJoin && otherCount < 5) {
    const newId = `dog-${otherCount + 1}`;
    const event: TableDynamicsEvent = {
      type: 'join',
      seatId: newId,
      handIndex: session.handsPlayed,
    };
    return {
      ...session,
      seats: [
        ...session.seats,
        {
          id: newId,
          isLearner: false,
          dogBreed: `breed-${otherCount + 1}`,
          hands: [],
        },
      ],
      dynamicsEvents: [...session.dynamicsEvents, event],
    };
  }

  if (shouldLeave && otherCount > 0) {
    const dogSeats = session.seats.filter((s) => !s.isLearner);
    const leaving = dogSeats[rng.nextInt(dogSeats.length)];
    const event: TableDynamicsEvent = {
      type: 'leave',
      seatId: leaving.id,
      handIndex: session.handsPlayed,
    };
    return {
      ...session,
      seats: session.seats.filter((s) => s.id !== leaving.id),
      dynamicsEvents: [...session.dynamicsEvents, event],
    };
  }

  return session;
}
