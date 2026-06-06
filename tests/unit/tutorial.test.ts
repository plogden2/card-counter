import { describe, it, expect } from 'vitest';
import {
  createTutorialProgress,
  getCurrentStepText,
  advanceTutorialStep,
  getLessonCount,
  isLessonComplete,
} from '@/domain/tutorial';
import { TUTORIAL_LESSONS } from '@/tutorial/lessons';

describe('tutorial progression', () => {
  it('defines five guided lessons (FR-001b)', () => {
    expect(getLessonCount()).toBe(5);
    expect(TUTORIAL_LESSONS.map((l) => l.id)).toEqual(['L1', 'L2', 'L3', 'L4', 'L5']);
  });

  it('starts at L1 step 0 by default', () => {
    const progress = createTutorialProgress();
    expect(progress.currentLessonId).toBe('L1');
    expect(progress.currentStep).toBe(0);
    expect(progress.completedLessons).toEqual([]);
  });

  it('returns current step coaching text', () => {
    const progress = createTutorialProgress('L1');
    const text = getCurrentStepText(progress);
    expect(text).toContain('Hi-Lo');
  });

  it('advances within a lesson before moving to the next', () => {
    let progress = createTutorialProgress('L1');
    const lesson = TUTORIAL_LESSONS[0];

    progress = advanceTutorialStep(progress);
    expect(progress.currentLessonId).toBe('L1');
    expect(progress.currentStep).toBe(1);

    for (let i = 1; i < lesson.steps.length; i++) {
      progress = advanceTutorialStep(progress);
    }

    expect(progress.completedLessons).toContain('L1');
    expect(progress.currentLessonId).toBe('L2');
    expect(progress.currentStep).toBe(0);
  });

  it('marks final lesson complete on last step', () => {
    let progress = createTutorialProgress('L5');
    const lesson = TUTORIAL_LESSONS[4];

    for (let i = 0; i < lesson.steps.length - 2; i++) {
      progress = advanceTutorialStep(progress);
      expect(isLessonComplete(progress)).toBe(false);
    }

    progress = advanceTutorialStep(progress);
    expect(isLessonComplete(progress)).toBe(true);

    progress = advanceTutorialStep(progress);
    expect(progress.completedLessons).toContain('L5');
    expect(isLessonComplete(progress)).toBe(true);
  });

  it('each lesson has a preset table configuration', () => {
    for (const lesson of TUTORIAL_LESSONS) {
      expect(lesson.presetConfig.deckCount).toBeGreaterThanOrEqual(1);
      expect(lesson.presetConfig.handsBeforeReshuffle).toBeGreaterThan(0);
    }
  });
});
