import type { BetClassification } from '@/domain/bet-sizing';
import type { StayOrLeaveAssessment } from '@/domain/stay-or-leave';

export function betCoachingHeadline(classification: BetClassification): string {
  switch (classification) {
    case 'under':
      return 'Under-bet detected';
    case 'over':
      return 'Over-bet detected';
    default:
      return 'Optimal bet';
  }
}

export function stayOrLeaveMessage(assessment: StayOrLeaveAssessment): string {
  if (assessment.recommendation === 'stay') {
    return 'Conditions favor staying at the table.';
  }
  const factors = assessment.factors.slice(0, 3).join('; ');
  return `Consider leaving: ${factors}`;
}
