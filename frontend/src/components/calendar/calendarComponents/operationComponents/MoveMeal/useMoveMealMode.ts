import { useState } from 'react';
import * as z from 'zod';
import useMeal from '../../../../../features/meal/useMeal';
import { updateMealSchema } from '../../../../../features/meal/schema';
import { useBackToDateWhenModeStarted } from '../../useCalendarMode';
import { Meal } from '../../../../../lib/graphql/generated/graphql';

export const MOVING_MEAL_MODES = {
  MOVING_MEAL_MODE: 'MOVING_MEAL_MODE',
};
export type MovingMealMode =
  (typeof MOVING_MEAL_MODES)[keyof typeof MOVING_MEAL_MODES];

export default (args: {
  calendarMode: any;
  updateCalendarMode: any;
  changeCalendarModeToDisplayCalendarMode: any;
  onDataChanged?: any;
}) => {
  const {
    calendarMode,
    updateCalendarMode,
    changeCalendarModeToDisplayCalendarMode,
    onDataChanged,
  } = args;
  const { updateMeal } = useMeal();
  const [selectedMeal, setSelectedMeal] = useState<Meal | null>(null);
  const { backToDateWhenModeStarted } = useBackToDateWhenModeStarted();

  const isMovingMealMode = calendarMode === MOVING_MEAL_MODES.MOVING_MEAL_MODE;
  const changeCalendarModeToMovingMealMode = () => {
    updateCalendarMode(MOVING_MEAL_MODES.MOVING_MEAL_MODE);
  };

  const startMovingMealMode = (meal) => {
    setSelectedMeal(meal);
    changeCalendarModeToMovingMealMode();
  };

  const backToWeekOfBeforeMoveMeal = () =>
    backToDateWhenModeStarted(new Date(selectedMeal!.date));

  const onDateClickForMovingMeal = (date: Date) => {
    if (!selectedMeal) return;
    const { id, mealType } = selectedMeal;
    // HACK: dishIdとかいらない情報渡しているように、オーバースペックだから、専用Mutation作る
    updateMeal(
      {
        dishId: selectedMeal.dish.id as number,
        meal: {
          id,
          mealType,
          date,
        } as z.infer<typeof updateMealSchema>,
      },
      {
        onCompleted: () => {
          if (onDataChanged) onDataChanged();
          backToWeekOfBeforeMoveMeal();
          changeCalendarModeToDisplayCalendarMode();
        },
      },
    );
  };

  return {
    selectedMeal,
    isMovingMealMode,
    startMovingMealMode,
    onDateClickForMovingMeal,
    changeCalendarModeToDisplayCalendarMode,
    backToWeekOfBeforeMoveMeal,
  };
};
