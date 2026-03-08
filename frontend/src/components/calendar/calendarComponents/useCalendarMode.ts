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

export const DISPLAY_CALENDAR_MODE = 'DISPLAY_CALENDAR_MODE';

export type CalendarMode =
  | typeof DISPLAY_CALENDAR_MODE
  | AssigningDishMode
  | SwappingMealMode
  | MovingMealMode;

export default ({ onDataChanged }) => {
  const [calendarMode, setCalendarMode] = useState(DISPLAY_CALENDAR_MODE);
  const updateCalendarMode = (mode: CalendarMode) => {
    setCalendarMode(mode);
  };

  const isDisplayCalendarMode = calendarMode === DISPLAY_CALENDAR_MODE;
  const isNotDisplayCalendarMode = calendarMode !== DISPLAY_CALENDAR_MODE;
  const changeCalendarModeToDisplayCalendarMode = () => {
    updateCalendarMode(DISPLAY_CALENDAR_MODE);
  };

  const useAssignDishModeResult = useAssignDishMode({
    calendarMode,
    updateCalendarMode,
    changeCalendarModeToDisplayCalendarMode,
    onDataChanged,
  });

  const useMoveMealModeResult = useMoveMealMode({
    calendarMode,
    updateCalendarMode,
    changeCalendarModeToDisplayCalendarMode,
    onDataChanged,
  });

  const useSwapMealsModeResult = useSwapMealsMode({
    calendarMode,
    updateCalendarMode,
    changeCalendarModeToDisplayCalendarMode,
    onDataChanged,
  });

  const calendarModeChangers = {
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
        changeCalendarModeToDisplayCalendarMode();
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
    isDisplayCalendarMode,
    isNotDisplayCalendarMode,
    calendarModeChangers,
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
