import React, { ReactNode } from 'react';
import { format } from 'date-fns';
import useRefreshCalendarData from '../../useRefreshCalendarData';
import useCalendarMode from '../useCalendarMode';
import useMeasureHeight from '../../../common/useMeasureHeight';
import DateCard from '../DateCard';
import AssignDish from '../operationComponents/AssignDish';
import MoveDish from '../operationComponents/MoveMeal';
import SwapMeals from '../operationComponents/SwapMeals';

type DateMeal = { date: Date; dayLabel: string; meals: any[] };

type Props = {
  dateMealsList: DateMeal[];
  fetchMealsLoading: boolean;
  refetchMealsForCalendar: any;
  refreshToPrev: any;
  refreshToNext: any;
  children: (props: any) => ReactNode;
};

export default (props: Props) => {
  const {
    dateMealsList,
    fetchMealsLoading,
    refetchMealsForCalendar,
    refreshToPrev,
    refreshToNext,
    children,
  } = props;

  const { refreshData } = useRefreshCalendarData({ refetchMealsForCalendar });

  const {
    isDisplayCalendarMode,
    useAssignDishModeResult,
    calendarModeChangers,
    useMoveMealModeResult,
    useSwapMealsModeResult,
    requireDisplayingBottomBar,
    onDateClick,
  } = useCalendarMode({
    onDataChanged: () => {
      refreshData();
    },
  });

  const [fixedComponentHeight, fixedComponentRef] = useMeasureHeight(
    requireDisplayingBottomBar,
  );

  const existMeals =
    dateMealsList &&
    dateMealsList.reduce((meals: any[], dateMeals) => {
      return meals.concat(dateMeals.meals);
    }, []).length > 0;
  if (fetchMealsLoading && !existMeals) {
    return <>Loading...</>;
  }

  return (
    <div>
      {/* カレンダーヘッダー */}
      {children({
        isDisplayCalendarMode,
        useAssignDishModeResult,
        refreshToPrev,
        refreshToNext,
      })}

      {/* DateCard を縦に並べる */}
      <div className="flex flex-col gap-1.5 px-2 py-2">
        {dateMealsList.map(({ date, dayLabel, meals }, dayIndex) => (
          <div
            key={`key_${dayIndex}`}
            onClick={() => onDateClick(date)}
            data-testid={`weekCalendarDateOf${format(date, 'yyyy-MM-dd')}`}
          >
            <DateCard
              date={date}
              dayLabel={dayLabel}
              meals={meals}
              isDisplayCalendarMode={isDisplayCalendarMode}
              calendarModeChangers={calendarModeChangers}
              onChanged={async () => {
                await refreshData();
              }}
              startSwappingMealsMode={
                useSwapMealsModeResult.startSwappingMealsMode
              }
            />
          </div>
        ))}
      </div>

      {/* 底部バー */}
      {requireDisplayingBottomBar && (
        <>
          <div
            ref={fixedComponentRef}
            className="w-full fixed bottom-0 bg-white"
          >
            <div className="border-t">
              {useAssignDishModeResult.inAssigningDishMode && (
                <AssignDish useAssignDishModeResult={useAssignDishModeResult} />
              )}
              {useMoveMealModeResult.isMovingMealMode && (
                <MoveDish useMoveDishModeResult={useMoveMealModeResult} />
              )}
              {useSwapMealsModeResult.isSwappingMealMode && (
                <SwapMeals useSwapMealsModeResult={useSwapMealsModeResult} />
              )}
            </div>
          </div>
          <div style={{ height: `${fixedComponentHeight}px` }} />
        </>
      )}
    </div>
  );
};
