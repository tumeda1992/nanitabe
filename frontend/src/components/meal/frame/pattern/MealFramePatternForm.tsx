'use client';

import React from 'react';
import useMealFramePattern from '../../../../features/meal/frame/pattern/useMealFramePattern';
import MealFramePatternFields, { type DaySlot } from './MealFramePatternFields';

type Props = {
  onSubmitSucceeded: () => void;
  defaultName?: string;
  defaultDaySlots?: DaySlot[];
};

export default ({
  onSubmitSucceeded,
  defaultName = '',
  defaultDaySlots = [],
}: Props) => {
  const { addMealFramePattern } = useMealFramePattern();

  return (
    <MealFramePatternFields
      defaultName={defaultName}
      defaultDaySlots={defaultDaySlots}
      submitLabel="作成する"
      submit={(name, entries) =>
        addMealFramePattern(
          { mealFramePattern: { name, entries } },
          {
            onCompleted: () => {
              onSubmitSucceeded();
            },
          },
        )
      }
    />
  );
};
