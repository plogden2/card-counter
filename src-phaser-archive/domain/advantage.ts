export function estimateAdvantage(trueCount: number): number {
  return trueCount * 0.5;
}

export function normalizedAdvantage(trueCount: number, worthwhileThreshold = 1): number {
  if (trueCount < worthwhileThreshold) {
    return Math.max(0, (trueCount + 2) / (worthwhileThreshold + 2));
  }
  return Math.min(1, 0.5 + (trueCount - worthwhileThreshold) * 0.1);
}
