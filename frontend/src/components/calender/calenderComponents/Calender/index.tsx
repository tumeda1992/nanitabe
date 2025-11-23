import React, { ReactNode } from 'react';
import { formatISO } from 'date-fns';
import useCalenderArrowComponent from '../useCalenderArrowComponent';
import useRefreshCalenderData from '../../useRefreshCalenderData';
import useCalenderMode from '../useCalenderMode';
import useMeasureHeight from '../../../common/useMeasureHeight';
import style from './index.module.scss';
import DateComponent from '../Date';
import CalenderMealIcon from '../MealIcon';
import AddMealIcon from '../MealIcon/AddMealIcon';
import AssignDish from '../operationComponents/AssignDish';
import MoveDish from '../operationComponents/MoveMeal';
import SwapMeals from '../operationComponents/SwapMeals';

type Props = {
  dateMealsList: { date: Date; dayLabel: string; meals: any[] }[];
  fetchMealsLoading: boolean;
  refetchMealsForCalender: any;
  refreshToPrev: any;
  refreshToNext: any;
  children: (props: any) => ReactNode;
};
export default (props: Props) => {
  const {
    dateMealsList,
    fetchMealsLoading,
    refetchMealsForCalender,
    refreshToPrev,
    refreshToNext,
    children,
  } = props;

  const { PreviousWeekDisplayButton, NextWeekDisplayButton } =
    useCalenderArrowComponent({
      refreshToPrev,
      refreshToNext,
    });

  const { refreshData } = useRefreshCalenderData({ refetchMealsForCalender });

  const {
    isDisplayCalenderMode,
    useAssignDishModeResult,
    calenderModeChangers,
    useMoveMealModeResult,
    useSwapMealsModeResult,
    requireDisplayingBottomBar,
    onDateClick,
  } = useCalenderMode({
    onDataChanged: () => {
      refreshData();
    },
  });

  const [fixedComponentHeight, fixedComponentRef] = useMeasureHeight(
    requireDisplayingBottomBar,
  );

  if (fetchMealsLoading) return <>Loading...</>;

  return (
    <div className={style['calender-container']}>
      <div className={style['calender-header']}>
        {children({ isDisplayCalenderMode, useAssignDishModeResult })}
      </div>
      <PreviousWeekDisplayButton />
      <table>
        <tbody>
          {dateMealsList.map(({ date, dayLabel, meals }, dayIndex) => {
            return (
              <tr
                key={`key_${dayIndex}`}
                onClick={() => onDateClick(date)}
                data-testid={`weekCalendarDateOf${date.toISOString()}`}
              >
                <th>
                  <DateComponent
                    date={date}
                    dayOfWeekLabel={dayLabel}
                    canAnythingExceptDisplay={isDisplayCalenderMode}
                    startSwappingMealsMode={
                      useSwapMealsModeResult.startSwappingMealsMode
                    }
                  />
                </th>
                <td className={style['dish-container__wrapper']}>
                  <div className={style['dish-container']}>
                    {meals?.map((meal) => (
                      <React.Fragment key={meal.id}>
                        <CalenderMealIcon
                          meal={meal}
                          onChanged={async () => {
                            await refreshData();
                          }}
                          canAnythingExeptDisplayDishName={
                            isDisplayCalenderMode
                          }
                          calenderModeChangers={calenderModeChangers}
                        />{' '}
                      </React.Fragment>
                    ))}
                    {isDisplayCalenderMode && (
                      <AddMealIcon
                        dateForAdd={date}
                        onAddSucceeded={async () => {
                          await refreshData();
                        }}
                      />
                    )}
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>

      {!requireDisplayingBottomBar && <NextWeekDisplayButton />}

      {/* 食事割当以外にも下からせり出るバーを使うようになったら条件変える */}
      {requireDisplayingBottomBar && (
        <>
          <div
            ref={fixedComponentRef}
            className={style['fixed-bar-from-bottom']}
          >
            <NextWeekDisplayButton />
            <div className={style['bottom-bar']}>
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
