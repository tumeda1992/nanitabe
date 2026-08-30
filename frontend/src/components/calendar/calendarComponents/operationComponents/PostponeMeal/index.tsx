import React from 'react';
import ChoosePostponedMeal from './ChoosePostponedMeal';
import ScheduleChosenPostponedMealForDate from './ScheduleChosenPostponedMealForDate';

type Props = {
  usePostponedMealModeResult: any;
};

export default (props: Props) => {
  const { usePostponedMealModeResult } = props;
  const { isChoosingPostponedMealMode, isSchedulingPostponedMealMode } =
    usePostponedMealModeResult;

  return (
    <>
      {isChoosingPostponedMealMode && (
        <ChoosePostponedMeal
          usePostponedMealModeResult={usePostponedMealModeResult}
        />
      )}

      {isSchedulingPostponedMealMode && (
        <ScheduleChosenPostponedMealForDate
          usePostponedMealModeResult={usePostponedMealModeResult}
        />
      )}
    </>
  );
};
