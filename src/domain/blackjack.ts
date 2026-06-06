import { updateCount, createCountState } from './counting';
import { isBlackjack, handValue, canDouble, canSplit, type Hand } from './hand';
import { buildShoe, draw, needsReshuffle, onHandSettled, reshuffle } from './shoe';
import { basicStrategyAction } from './strategy';
import { validateTableConfig, STARTING_BANKROLL } from './table-config';
import type { SessionState, Seat } from './session';
import type { Card } from './card';
import type { Rng } from '@/lib/rng';
import type { GameMode } from './session';
import type { BetModelId } from './bet-models';
import type { TableConfiguration } from './table-config';

export type HandAction =
  | 'hit'
  | 'stand'
  | 'double'
  | 'split'
  | 'insurance-accept'
  | 'insurance-decline'
  | 'place-bet';

export function createSession(
  mode: GameMode,
  config: Partial<TableConfiguration>,
  balance: number = STARTING_BANKROLL,
  betModel: BetModelId = 'spread-table',
  rng: Rng,
): SessionState {
  const tableConfiguration = validateTableConfig(config);
  const shoe = buildShoe(tableConfiguration.deckCount, rng, tableConfiguration.handsBeforeReshuffle);
  const seats = createSeats(tableConfiguration.initialOtherPlayers);

  return {
    mode,
    tableConfiguration,
    shoe,
    seats,
    dealerCards: [],
    dealerHoleHidden: true,
    countState: createCountState(shoe.cards.length),
    balance,
    sessionStartBalance: balance,
    analytics: [],
    currentBetModel: betModel,
    handsPlayed: 0,
    dynamicsEvents: [],
    phase: 'betting',
    activeSeatId: 'learner',
    activeHandIndex: 0,
    currentWager: 0,
    lowAdvantageStreak: 0,
  };
}

function createSeats(otherPlayers: number): Seat[] {
  const seats: Seat[] = [
    { id: 'learner', isLearner: true, dogBreed: 'learner-dog', hands: [] },
  ];
  for (let i = 1; i <= otherPlayers; i++) {
    seats.push({
      id: `dog-${i}`,
      isLearner: false,
      dogBreed: `breed-${i}`,
      hands: [],
    });
  }
  return seats;
}

export function placeBet(session: SessionState, wager: number): SessionState {
  if (session.phase !== 'betting') {
    throw new Error('Cannot place bet outside betting phase');
  }
  const max = Math.min(session.balance, session.tableConfiguration.tableMaxBet);
  const clamped = Math.max(
    session.tableConfiguration.tableMinBet,
    Math.min(wager, max),
  );
  return { ...session, currentWager: clamped };
}

export function dealInitial(session: SessionState, rng: Rng): SessionState {
  if (session.currentWager < session.tableConfiguration.tableMinBet) {
    throw new Error('Must place bet before dealing');
  }

  let state = { ...session };
  let shoe = state.shoe;

  if (needsReshuffle(shoe, state.seats.length * 2 + 2)) {
    shoe = reshuffle(shoe, state.tableConfiguration.deckCount, rng);
    state = {
      ...state,
      shoe,
      countState: createCountState(shoe.cards.length),
    };
  }

  const seats = state.seats.map((seat) => ({
    ...seat,
    hands: [
      {
        cards: [] as Card[],
        wager: seat.isLearner ? state.currentWager : state.tableConfiguration.tableMinBet,
        status: 'active' as const,
        isSplit: false,
        ownerSeatId: seat.id,
      },
    ],
  }));

  let allCards: Card[] = [];
  for (let round = 0; round < 2; round++) {
    for (const seat of seats) {
      const result = draw(shoe, 1);
      shoe = result.shoe;
      seat.hands[0].cards.push(result.cards[0]);
      allCards.push(result.cards[0]);
    }
    const dealerResult = draw(shoe, 1);
    shoe = dealerResult.shoe;
    if (round === 0) {
      state = { ...state, dealerCards: [dealerResult.cards[0]] };
    } else {
      state = {
        ...state,
        dealerCards: [...state.dealerCards, dealerResult.cards[0]],
        dealerHoleHidden: true,
      };
      allCards.push(dealerResult.cards[0]);
    }
  }

  const visibleCards = [
    ...seats.flatMap((s) => s.hands[0].cards),
    state.dealerCards[0],
  ];
  const countState = updateCount(state.countState, visibleCards, shoe.cards.length);

  const dealerUpAce = state.dealerCards[0].rank === 'A';
  const phase = dealerUpAce ? 'insurance' : 'player-turn';

  return {
    ...state,
    shoe,
    seats,
    countState,
    phase,
    activeSeatId: 'learner',
    activeHandIndex: 0,
    dealerHoleHidden: true,
  };
}

export function applyAction(
  session: SessionState,
  seatId: string,
  action: HandAction,
  rng: Rng,
): SessionState {
  let state = { ...session };

  if (action === 'insurance-accept' || action === 'insurance-decline') {
    return handleInsurance(state, action);
  }

  if (state.phase !== 'player-turn') {
    throw new Error(`Cannot apply ${action} in phase ${state.phase}`);
  }

  const seat = state.seats.find((s) => s.id === seatId);
  if (!seat) throw new Error(`Seat ${seatId} not found`);

  const hand = seat.hands[state.activeHandIndex];
  if (!hand || hand.status !== 'active') {
    throw new Error('No active hand');
  }

  switch (action) {
    case 'hit':
      state = hit(state, seat, hand, rng);
      break;
    case 'stand':
      state = stand(state, seat, hand);
      break;
    case 'double':
      if (!canDouble(hand)) throw new Error('Cannot double');
      state = doubleDown(state, seat, hand, rng);
      break;
    case 'split':
      if (!canSplit(hand)) throw new Error('Cannot split');
      state = splitHand(state, seat, hand, rng);
      break;
    default:
      throw new Error(`Unknown action: ${action}`);
  }

  if (state.phase === 'player-turn') {
    state = advanceTurn(state, rng);
  }

  if (state.phase === 'dealer-turn') {
    state = playDealer(state, rng);
    state = settleHand(state);
  }

  return state;
}

function handleInsurance(
  session: SessionState,
  action: 'insurance-accept' | 'insurance-decline',
): SessionState {
  if (session.phase !== 'insurance') {
    throw new Error('Insurance not offered');
  }
  if (session.dealerCards[0].rank !== 'A') {
    throw new Error('Insurance only when dealer shows Ace');
  }

  const seats = session.seats.map((seat) => {
    if (!seat.isLearner) return seat;
    const hand = { ...seat.hands[0] };
    if (action === 'insurance-accept') {
      hand.insuranceWager = Math.floor(hand.wager / 2);
    }
    return { ...seat, hands: [hand] };
  });

  const dealerBJ = isBlackjack(session.dealerCards);
  if (dealerBJ) {
    let balance = session.balance;
    const learnerHand = seats.find((s) => s.isLearner)!.hands[0];
    if (learnerHand.insuranceWager) {
      balance += learnerHand.insuranceWager * 2;
    }
    if (isBlackjack(learnerHand.cards)) {
      balance += Math.floor(learnerHand.wager * 2.5);
    } else {
      balance -= learnerHand.wager;
    }
    return settleEarly(session, seats, balance);
  }

  return {
    ...session,
    seats,
    phase: 'player-turn',
    activeSeatId: 'learner',
    activeHandIndex: 0,
  };
}

function hit(
  session: SessionState,
  seat: Seat,
  hand: Hand,
  _rng: Rng,
): SessionState {
  const result = draw(session.shoe, 1);
  const newCard = result.cards[0];
  const newHand: Hand = {
    ...hand,
    cards: [...hand.cards, newCard],
  };
  const { total } = handValue(newHand.cards);
  if (total > 21) {
    newHand.status = 'bust';
  }

  const visible = [newCard];
  const countState = updateCount(session.countState, visible, result.shoe.cards.length);

  const seats = updateSeatHand(session.seats, seat.id, session.activeHandIndex, newHand);

  return { ...session, shoe: result.shoe, seats, countState };
}

function stand(session: SessionState, seat: Seat, hand: Hand): SessionState {
  const newHand: Hand = { ...hand, status: 'stood' };
  const seats = updateSeatHand(session.seats, seat.id, session.activeHandIndex, newHand);
  return { ...session, seats };
}

function doubleDown(
  session: SessionState,
  seat: Seat,
  hand: Hand,
  rng: Rng,
): SessionState {
  let balance = session.balance - hand.wager;
  const newHand: Hand = { ...hand, wager: hand.wager * 2, doubled: true };
  let state = hit({ ...session, balance }, seat, newHand, rng);
  const updatedHand = state.seats.find((s) => s.id === seat.id)!.hands[state.activeHandIndex];
  if (updatedHand.status === 'active') {
    updatedHand.status = 'stood';
    state = {
      ...state,
      seats: updateSeatHand(state.seats, seat.id, state.activeHandIndex, updatedHand),
    };
  }
  return state;
}

function splitHand(
  session: SessionState,
  seat: Seat,
  hand: Hand,
  _rng: Rng,
): SessionState {
  if (seat.hands.length >= 4) throw new Error('Max splits reached');

  let balance = session.balance - hand.wager;
  const card1 = hand.cards[0];
  const card2 = hand.cards[1];

  const hand1: Hand = {
    cards: [card1],
    wager: hand.wager,
    status: 'active',
    isSplit: true,
    ownerSeatId: seat.id,
  };
  const hand2: Hand = {
    cards: [card2],
    wager: hand.wager,
    status: 'active',
    isSplit: true,
    ownerSeatId: seat.id,
  };

  let state: SessionState = { ...session, balance };
  let drawResult = draw(state.shoe, 1);
  hand1.cards.push(drawResult.cards[0]);
  state = {
    ...state,
    shoe: drawResult.shoe,
    countState: updateCount(state.countState, drawResult.cards, drawResult.shoe.cards.length),
  };

  drawResult = draw(state.shoe, 1);
  hand2.cards.push(drawResult.cards[0]);
  state = {
    ...state,
    shoe: drawResult.shoe,
    countState: updateCount(state.countState, drawResult.cards, drawResult.shoe.cards.length),
  };

  const seats = session.seats.map((s) =>
    s.id === seat.id ? { ...s, hands: [hand1, hand2] } : s,
  );

  return { ...state, seats, activeHandIndex: 0 };
}

function advanceTurn(session: SessionState, rng: Rng): SessionState {
  const seat = session.seats.find((s) => s.id === session.activeSeatId);
  if (!seat) return finishPlayerTurn(session, rng);

  const hand = seat.hands[session.activeHandIndex];
  if (hand?.status === 'active') {
    return session;
  }

  if (session.activeHandIndex < seat.hands.length - 1) {
    return { ...session, activeHandIndex: session.activeHandIndex + 1 };
  }

  if (seat.isLearner) {
    return finishPlayerTurn(session, rng);
  }

  return { ...session, phase: 'dealer-turn' };
}

function finishPlayerTurn(session: SessionState, rng: Rng): SessionState {
  let state = { ...session };
  for (const seat of state.seats) {
    if (seat.isLearner) continue;
    state = playDogSeat(state, seat, rng);
  }
  return { ...state, phase: 'dealer-turn' };
}

function playDogSeat(session: SessionState, seat: Seat, rng: Rng): SessionState {
  let state: SessionState = { ...session, activeSeatId: seat.id, activeHandIndex: 0 };
  while (state.phase === 'player-turn' && state.activeSeatId === seat.id) {
    const currentSeat = state.seats.find((s) => s.id === seat.id)!;
    const hand = currentSeat.hands[state.activeHandIndex];
    if (!hand || hand.status !== 'active') {
      state = advanceTurn(state, rng);
      continue;
    }
    const action = basicStrategyAction(hand, state.dealerCards[0]);
    if (action === 'double' && canDouble(hand) && state.balance >= hand.wager) {
      state = applyAction(state, seat.id, 'double', rng);
    } else if (action === 'split' && canSplit(hand) && state.balance >= hand.wager) {
      state = applyAction(state, seat.id, 'split', rng);
    } else if (action === 'hit') {
      state = applyAction(state, seat.id, 'hit', rng);
    } else {
      state = applyAction(state, seat.id, 'stand', rng);
    }
  }
  return state;
}

function playDealer(session: SessionState, _rng: Rng): SessionState {
  let state: SessionState = {
    ...session,
    dealerHoleHidden: false,
  };

  const holeCard = state.dealerCards[1];
  if (holeCard) {
    state = {
      ...state,
      countState: updateCount(
        state.countState,
        [holeCard],
        state.shoe.cards.length,
      ),
    };
  }

  let { total, soft } = handValue(state.dealerCards);
  while (total < 17 || (total === 17 && soft)) {
    const result = draw(state.shoe, 1);
    state = {
      ...state,
      shoe: result.shoe,
      dealerCards: [...state.dealerCards, ...result.cards],
      countState: updateCount(state.countState, result.cards, result.shoe.cards.length),
    };
    ({ total, soft } = handValue(state.dealerCards));
  }

  return state;
}

export function settleHand(session: SessionState): SessionState {
  const dealerTotal = handValue(session.dealerCards).total;
  const dealerBJ = isBlackjack(session.dealerCards) && session.dealerCards.length === 2;
  let balance = session.balance;

  for (const seat of session.seats) {
    for (const hand of seat.hands) {
      if (hand.status === 'bust') {
        balance -= hand.wager;
        continue;
      }
      const playerTotal = handValue(hand.cards).total;
      const playerBJ = isBlackjack(hand.cards) && hand.cards.length === 2 && !hand.isSplit;

      if (dealerBJ) {
        if (playerBJ) continue;
        balance -= hand.wager;
      } else if (playerBJ) {
        balance += Math.floor(hand.wager * 1.5);
      } else if (playerTotal > dealerTotal || dealerTotal > 21) {
        balance += hand.wager;
      } else if (playerTotal < dealerTotal) {
        balance -= hand.wager;
      }
    }
  }

  let shoe = onHandSettled(session.shoe, session.tableConfiguration.handsBeforeReshuffle);

  return {
    ...session,
    balance,
    shoe,
    phase: 'settled',
    handsPlayed: session.handsPlayed + 1,
    dealerHoleHidden: false,
  };
}

function settleEarly(
  session: SessionState,
  seats: Seat[],
  balance: number,
): SessionState {
  let shoe = onHandSettled(session.shoe, session.tableConfiguration.handsBeforeReshuffle);
  const countState = updateCount(session.countState, session.dealerCards.slice(1), session.shoe.cards.length);

  return {
    ...session,
    seats,
    balance,
    shoe,
    countState,
    phase: 'settled',
    handsPlayed: session.handsPlayed + 1,
    dealerHoleHidden: false,
  };
}

function updateSeatHand(
  seats: Seat[],
  seatId: string,
  handIndex: number,
  hand: Hand,
): Seat[] {
  return seats.map((s) => {
    if (s.id !== seatId) return s;
    const hands = [...s.hands];
    hands[handIndex] = hand;
    return { ...s, hands };
  });
}

export { handValue };
