export interface Rng {
  next(): number;
  nextInt(max: number): number;
}

export function createRng(seed: number): Rng {
  let state = seed >>> 0;
  return {
    next(): number {
      state = (state * 1664525 + 1013904223) >>> 0;
      return state / 0x100000000;
    },
    nextInt(max: number): number {
      if (max <= 0) throw new RangeError('max must be positive');
      return Math.floor(this.next() * max);
    },
  };
}

export function shuffle<T>(items: T[], rng: Rng): T[] {
  const result = [...items];
  for (let i = result.length - 1; i > 0; i--) {
    const j = rng.nextInt(i + 1);
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
}
