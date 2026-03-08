import { useState, useEffect } from 'react';
import useAssignDishMode, {
  AssigningDishMode,
} from './operationComponents/AssignDish/useAssignDishMode';
import useMoveMealMode, {
  MovingMealMode,
} from './operationComponents/MoveMeal/useMoveMealMode';
import useSwapMealsMode, {
  SwappingMealMode,
} from './operationComponents/SwapMeals/useSwapMealsMode';
import {
  isMonthPath,
  monthCalendarPagePathOf,
} from '../../../app/calendar/month/[date]/consts';
import { weekCalendarPagePathOf } from '../../../app/calendar/week/[date]/consts';
import { useLogicalHistory } from '../../../app/logical-history';

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

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        changeCalenderModeToDisplayCalenderMode();
      }
    };

    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, []);

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
  const { currentPathAndQuery, pushHistory } = useLogicalHistory();

  const backToDateWhenModeStarted = (dateWhenModeStarted: Date) => {
    const moveTargetPath = (() => {
      if (isMonthPath(currentPathAndQuery)) {
        return monthCalendarPagePathOf(dateWhenModeStarted);
      }
      return weekCalendarPagePathOf(dateWhenModeStarted);
    })();
    if (moveTargetPath !== currentPathAndQuery) {
      pushHistory(moveTargetPath);
    }
  };

  return { backToDateWhenModeStarted };
};
