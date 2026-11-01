import { useEffect, useRef, useState } from 'react';
import usePostponedMeal from '../../../../../features/meal/postponed/usePostponedMeal';

import { POSTPONED_MEAL_MODES } from '../../calendarMode';
import type { CalendarModeControls } from '../../calendarMode';
export { POSTPONED_MEAL_MODES } from '../../calendarMode';
export type { PostponedMealMode } from '../../calendarMode';

export default (args: CalendarModeControls) => {
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
  const [refreshError, setRefreshError] = useState<string | null>(null);
  const [scheduleError, setScheduleError] = useState<string | null>(null);
  const [isScheduling, setIsScheduling] = useState(false);
  const isWorking = useRef(false);
  const refreshPending = useRef(false);


  const startPostponedMealMode = () => {
    setRefreshError(null);
    setScheduleError(null);
    refreshPending.current = false;
    setSelectedPostponedMeal(null);
    changeCalendarModeToChoosingPostponedMealMode();
  };

  const selectPostponedMeal = (postponedMeal) => {
    setRefreshError(null);
    setScheduleError(null);
    refreshPending.current = false;
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

  const refreshAfterScheduling = async () => {
    isWorking.current = true;
    setIsScheduling(true);
    setRefreshError(null);
    try {
      if (onDataChanged) await onDataChanged();
      await refetchPostponedMeals();
      refreshPending.current = false;
      setSelectedPostponedMeal(null);
      changeCalendarModeToDisplayCalendarMode();
    } catch {
      setRefreshError('食事の登録は完了しましたが、表示の更新に失敗しました。');
    } finally {
      isWorking.current = false;
      setIsScheduling(false);
    }
  };

  const retryRefresh = async () => {
    if (!refreshPending.current || isWorking.current) return;
    await refreshAfterScheduling();
  };

  const onDateClickForSchedulingPostponedMeal = (date: Date) => {
    if (!selectedPostponedMeal || isWorking.current || refreshPending.current) return;
    isWorking.current = true;
    setIsScheduling(true);
    setScheduleError(null);
    const onError = () => {
      isWorking.current = false;
      setIsScheduling(false);
      setScheduleError('食事を登録できませんでした。もう一度お試しください。');
    };
    void Promise.resolve(schedulePostponedMeal(
      { postponedMealId: selectedPostponedMeal.id, date },
      {
        onCompleted: async () => {
          refreshPending.current = true;
          await refreshAfterScheduling();
        },
        onError,
      },
    )).catch(onError);
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
    refreshError,
    scheduleError,
    isScheduling,
    retryRefresh,
  };
};
