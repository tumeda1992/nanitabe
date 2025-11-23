import { useState } from 'react';
import { useRouter } from 'next/router';
import { usePathname } from 'next/navigation';
import useAssignDishMode, {
  AssigningDishMode,
} from './operationComponents/AssignDish/useAssignDishMode';
import useMoveMealMode, {
  MovingMealMode,
} from './operationComponents/MoveMeal/useMoveMealMode';
import useSwapMealsMode, {
  SwappingMealMode,
} from './operationComponents/SwapMeals/useSwapMealsMode';
import { weekCalenderPageUrlOf } from '../../../pages/calender/week/[date]';
import {
  isMonthPath,
  monthCalenderPageUrlOf,
} from '../../../pages/calender/month/[date]';

export const DISPLAY_CALENDER_MODE = 'DISPLAY_CALENDER_MODE';

export type CalenderMode =
  | typeof DISPLAY_CALENDER_MODE
  | AssigningDishMode
  | SwappingMealMode
  | MovingMealMode;

export default ({ onDataChanged }) => {
  const [calenderMode, setCalenderMode] = useState(DISPLAY_CALENDER_MODE);
  const updateCalenderMode = (mode: CalenderMode) => {
    setCalenderMode(mode);
  };

  const isDisplayCalenderMode = calenderMode === DISPLAY_CALENDER_MODE;
  const isNotDisplayCalenderMode = calenderMode !== DISPLAY_CALENDER_MODE;
  const changeCalenderModeToDisplayCalenderMode = () => {
    updateCalenderMode(DISPLAY_CALENDER_MODE);
  };

  const useAssignDishModeResult = useAssignDishMode({
    calenderMode,
    updateCalenderMode,
    changeCalenderModeToDisplayCalenderMode,
    onDataChanged,
  });

  const useMoveMealModeResult = useMoveMealMode({
    calenderMode,
    updateCalenderMode,
    changeCalenderModeToDisplayCalenderMode,
    onDataChanged,
  });

  const useSwapMealsModeResult = useSwapMealsMode({
    calenderMode,
    updateCalenderMode,
    changeCalenderModeToDisplayCalenderMode,
    onDataChanged,
  });

  const calenderModeChangers = {
    startMovingDishMode: useMoveMealModeResult.startMovingMealMode,
  };

  const onDateClick = (date: Date) => {
    if (useAssignDishModeResult.isAssigningSelectedDishMode) {
      useAssignDishModeResult.onDateClickForAssigningDish(date);
      return;
    }
    if (useMoveMealModeResult.isMovingMealMode) {
      useMoveMealModeResult.onDateClickForMovingMeal(date);
      return;
    }
    if (useSwapMealsModeResult.isSwappingMealMode) {
      useSwapMealsModeResult.onDateClickForSwappingMeals(date);
      // return;
    }
  };

  const requireDisplayingBottomBar =
    useAssignDishModeResult.inAssigningDishMode ||
    useMoveMealModeResult.isMovingMealMode ||
    useSwapMealsModeResult.isSwappingMealMode;

  return {
    isDisplayCalenderMode,
    isNotDisplayCalenderMode,
    calenderModeChangers,
    useAssignDishModeResult,
    useMoveMealModeResult,
    useSwapMealsModeResult,
    requireDisplayingBottomBar,
    onDateClick,
  };
};

// 以下、カレンダーモードで流用されるものを定義

export const useBackToDateWhenModeStarted = () => {
  const router = useRouter();
  const currentPath = usePathname();

  const backToDateWhenModeStarted = (dateWhenModeStarted: Date) => {
    const moveTargetPath = (() => {
      if (isMonthPath(currentPath)) {
        return monthCalenderPageUrlOf(dateWhenModeStarted);
      }
      return weekCalenderPageUrlOf(dateWhenModeStarted);
    })();
    if (moveTargetPath !== currentPath) {
      router.push(moveTargetPath);
    }
  };

  return { backToDateWhenModeStarted };
};
