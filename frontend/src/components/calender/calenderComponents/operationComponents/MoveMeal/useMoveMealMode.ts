import { useState } from 'react';
import * as z from 'zod';
import useMeal from '../../../../../features/meal/useMeal';
import { updateMealSchema } from '../../../../../features/meal/schema';
import { useBackToDateWhenModeStarted } from '../../useCalenderMode';

export const MOVING_MEAL_MODES = {
  MOVING_MEAL_MODE: 'MOVING_MEAL_MODE',
};
export type MovingMealMode =
  (typeof MOVING_MEAL_MODES)[keyof typeof MOVING_MEAL_MODES];

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
  const { updateMeal } = useMeal();
  const [selectedMeal, setSelectedMeal] = useState(null);
  const { backToDateWhenModeStarted } = useBackToDateWhenModeStarted();

  const isMovingMealMode = calenderMode === MOVING_MEAL_MODES.MOVING_MEAL_MODE;
  const changeCalenderModeToMovingMealMode = () => {
    updateCalenderMode(MOVING_MEAL_MODES.MOVING_MEAL_MODE);
  };

  const startMovingMealMode = (meal) => {
    setSelectedMeal(meal);
    changeCalenderModeToMovingMealMode();
  };

  const backToWeekOfBeforeMoveMeal = () =>
    backToDateWhenModeStarted(new Date(selectedMeal.date));

  const onDateClickForMovingMeal = (date: Date) => {
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
          changeCalenderModeToDisplayCalenderMode();
        },
      },
    );
  };

  return {
    selectedMeal,
    isMovingMealMode,
    startMovingMealMode,
    onDateClickForMovingMeal,
    changeCalenderModeToDisplayCalenderMode,
    backToWeekOfBeforeMoveMeal,
  };
};
