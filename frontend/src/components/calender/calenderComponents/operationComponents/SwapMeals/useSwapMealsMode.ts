import { useState } from 'react';
import useMeal from '../../../../../features/meal/useMeal';
import { useBackToDateWhenModeStarted } from '../../useCalenderMode';

export const SWAPPING_MEALS_MODES = {
  SWAPPING_MEALS_MODE: 'SWAPPING_MEALS_MODE',
};
export type SwappingMealMode =
  (typeof SWAPPING_MEALS_MODES)[keyof typeof SWAPPING_MEALS_MODES];

export default (args: {
  calenderMode: any;
  updateCalenderMode: any;
  changeCalenderModeToDisplayCalenderMode: any;
  onDataChanged?: any;
}) => {
  const {
    calenderMode,
    updateCalenderMode,
    changeCalenderModeToDisplayCalenderMode,
    onDataChanged,
  } = args;
  const { swapMealsBetweenDays } = useMeal();
  const [swapTargetDate1, setSwapTargetDate1] = useState(null);
  const { backToDateWhenModeStarted } = useBackToDateWhenModeStarted();

  const isSwappingMealMode =
    calenderMode === SWAPPING_MEALS_MODES.SWAPPING_MEALS_MODE;
  const changeCalenderModeToMovingDishMode = () => {
    updateCalenderMode(SWAPPING_MEALS_MODES.SWAPPING_MEALS_MODE);
  };

  const startSwappingMealsMode = (date) => {
    setSwapTargetDate1(date);
    changeCalenderModeToMovingDishMode();
  };

  const backToWeekOfBeforeSwapMeal = () =>
    backToDateWhenModeStarted(swapTargetDate1);

  const onDateClickForSwappingMeals = (swapTargetDate2: Date) => {
    swapMealsBetweenDays(
      {
        date1: swapTargetDate1,
        date2: swapTargetDate2,
      },
      {
        onCompleted: () => {
          if (onDataChanged) onDataChanged();
          backToDateWhenModeStarted(swapTargetDate1);
          changeCalenderModeToDisplayCalenderMode();
        },
      },
    );
  };

  return {
    startSwappingMealsMode,
    isSwappingMealMode,
    onDateClickForSwappingMeals,
    changeCalenderModeToDisplayCalenderMode,
    backToWeekOfBeforeSwapMeal,
    swapTargetDate1,
  };
};
