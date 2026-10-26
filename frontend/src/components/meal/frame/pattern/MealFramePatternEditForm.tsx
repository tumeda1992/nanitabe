'use client';

import React from 'react';
import MealFramePatternFields, { type DaySlot } from './MealFramePatternFields';
import type { UpdateMealFramePatternFunc } from '../../../../features/meal/frame/pattern/useMealFramePattern';

type PatternEntry = {
  id?: number;
  dayOffset: number;
  mealType: number;
  mealFrameId: number;
  mealFrameName?: string;
};

type Pattern = {
  id: number;
  name: string;
  entries: PatternEntry[];
};

type Props = {
  pattern: Pattern;
  onSubmitSucceeded: () => void;
  updateMealFramePattern: UpdateMealFramePatternFunc;
};

const buildDaySlotsFromEntries = (entries: PatternEntry[]): DaySlot[] => {
  if (entries.length === 0) return [];

  const maxDay = Math.max(...entries.map((e) => e.dayOffset));
  const slots: DaySlot[] = Array.from({ length: maxDay }, () => ({
    entries: [],
  }));

  entries.forEach((entry) => {
    slots[entry.dayOffset - 1].entries.push({
      dayOffset: entry.dayOffset,
      mealType: entry.mealType,
      mealFrameId: entry.mealFrameId,
    });
  });

  return slots;
};

export default ({
  pattern,
  onSubmitSucceeded,
  updateMealFramePattern,
}: Props) => (
  <MealFramePatternFields
    defaultName={pattern.name}
    defaultDaySlots={() => buildDaySlotsFromEntries(pattern.entries)}
    submitLabel="更新する"
    submit={(name, entries) =>
      updateMealFramePattern(
        { mealFramePattern: { id: pattern.id, name, entries } },
        {
          onCompleted: () => {
            onSubmitSucceeded();
          },
        },
      )
    }
  />
);
