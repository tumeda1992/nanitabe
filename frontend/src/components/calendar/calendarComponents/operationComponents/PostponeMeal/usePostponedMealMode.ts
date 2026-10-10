import { useEffect, useState } from 'react';
import usePostponedMeal from '../../../../../features/meal/postponed/usePostponedMeal';

export const POSTPONED_MEAL_MODES = {
  CHOOSING_POSTPONED_MEAL_MODE: 'CHOOSING_POSTPONED_MEAL_MODE',
  SCHEDULING_POSTPONED_MEAL_MODE: 'SCHEDULING_POSTPONED_MEAL_MODE',
};
export type PostponedMealMode =
  (typeof POSTPONED_MEAL_MODES)[keyof typeof POSTPONED_MEAL_MODES];

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

  const isChoosingPostponedMealMode =
    calendarMode === POSTPONED_MEAL_MODES.CHOOSING_POSTPONED_MEAL_MODE;
  const isSchedulingPostponedMealMode =
    calendarMode === POSTPONED_MEAL_MODES.SCHEDULING_POSTPONED_MEAL_MODE;
  const inPostponedMealMode =
    isChoosingPostponedMealMode || isSchedulingPostponedMealMode;

  const changeCalendarModeToChoosingPostponedMealMode = () => {
    updateCalendarMode(POSTPONED_MEAL_MODES.CHOOSING_POSTPONED_MEAL_MODE);
  };
  const changeCalendarModeToSchedulingPostponedMealMode = () => {
    updateCalendarMode(POSTPONED_MEAL_MODES.SCHEDULING_POSTPONED_MEAL_MODE);
  };

  const [selectedPostponedMeal, setSelectedPostponedMeal] = useState<any>(null);

  const startPostponedMealMode = () => {
    setSelectedPostponedMeal(null);
    changeCalendarModeToChoosingPostponedMealMode();
  };

  const selectPostponedMeal = (postponedMeal) => {
    setSelectedPostponedMeal(postponedMeal);
    changeCalendarModeToSchedulingPostponedMealMode();
  };

  const {
    postponedMeals,
    fetchPostponedMealsLoading,
    refetchPostponedMeals,
    schedulePostponedMeal,
  } = usePostponedMeal({ requireFetchedData: inPostponedMealMode });

  // 一覧を開くたびに最新化する。延期・確定はいずれもこのhookの外側（食事カード）や
  // 別queryのcacheを触らないため、開いた時点で取り直さないと古い一覧が出る。
  useEffect(() => {
    if (isChoosingPostponedMealMode) refetchPostponedMeals();
  }, [isChoosingPostponedMealMode]);

  const onDateClickForSchedulingPostponedMeal = (date: Date) => {
    if (!selectedPostponedMeal) return;
    schedulePostponedMeal(
      { postponedMealId: selectedPostponedMeal.id, date },
      {
        onCompleted: async () => {
          // onDataChanged（refreshData）は apolloClient.clearStore を含む。
          // 完了を待たずに再取得を始めると、in flightのqueryがstore resetと衝突して
          // "Store reset while query was in flight" になる。必ず待つ。
          if (onDataChanged) await onDataChanged();
          // モードを戻すとqueryがskipされるため、閉じる前に取り直す
          await refetchPostponedMeals();
          setSelectedPostponedMeal(null);
          changeCalendarModeToDisplayCalendarMode();
        },
      },
    );
  };

  return {
    inPostponedMealMode,

    isChoosingPostponedMealMode,
    changeCalendarModeToChoosingPostponedMealMode,
    startPostponedMealMode,
    changeCalendarModeToDisplayCalendarMode,

    isSchedulingPostponedMealMode,
    changeCalendarModeToSchedulingPostponedMealMode,
    onDateClickForSchedulingPostponedMeal,

    postponedMeals,
    fetchPostponedMealsLoading,
    refetchPostponedMeals,

    selectedPostponedMeal,
    selectPostponedMeal,
  };
};
