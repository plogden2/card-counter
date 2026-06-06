import { TUTORIAL_LESSONS, getLesson, getNextLessonId } from '@/tutorial/lessons';

export interface TutorialProgress {
  currentLessonId: string;
  currentStep: number;
  completedLessons: string[];
}

export function createTutorialProgress(lessonId = 'L1'): TutorialProgress {
  return {
    currentLessonId: lessonId,
    currentStep: 0,
    completedLessons: [],
  };
}

export function getCurrentStepText(progress: TutorialProgress): string {
  const lesson = getLesson(progress.currentLessonId);
  if (!lesson) return '';
  return lesson.steps[progress.currentStep] ?? '';
}

export function advanceTutorialStep(progress: TutorialProgress): TutorialProgress {
  const lesson = getLesson(progress.currentLessonId);
  if (!lesson) return progress;

  const nextStep = progress.currentStep + 1;
  if (nextStep < lesson.steps.length) {
    return { ...progress, currentStep: nextStep };
  }

  const completedLessons = [...progress.completedLessons, progress.currentLessonId];
  const nextLessonId = getNextLessonId(progress.currentLessonId);
  if (!nextLessonId) {
    return { ...progress, completedLessons, currentStep: lesson.steps.length };
  }

  return {
    currentLessonId: nextLessonId,
    currentStep: 0,
    completedLessons,
  };
}

export function getLessonCount(): number {
  return TUTORIAL_LESSONS.length;
}

export function isLessonComplete(progress: TutorialProgress): boolean {
  const lesson = getLesson(progress.currentLessonId);
  if (!lesson) return true;
  const isLast = !getNextLessonId(progress.currentLessonId);
  return isLast && progress.currentStep >= lesson.steps.length - 1;
}
