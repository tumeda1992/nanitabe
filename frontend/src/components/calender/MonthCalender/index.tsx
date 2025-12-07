'use client';

import React from 'react';
import {
  format,
  isSameDay,
  getDay,
  eachDayOfInterval,
  addHours,
} from 'date-fns';
import Calender from '../calenderComponents/Calender';
import useMeal from '../../../features/meal/useMeal';
import style from '../calenderComponents/Calender/index.module.scss';
import CalenderMenu from '../WeekCalender/CalenderMenu';
import {
  DAY_OF_FRIDAY,
  DAY_OF_MONDAY,
  DAY_OF_SATURDAY,
  DAY_OF_SUNDAY,
  DAY_OF_THURSDAY,
  DAY_OF_TUESDAY,
  DAY_OF_WEDNESDAY,
} from '../calenderComponents/useCalenderDay';
import { useDisplayDate } from './useMonthCalenderDate';

export type Props = {
  date: Date;
};

export default (props: Props) => {
  const { date: dateArg } = props;

  const {
    firstDayOfMonth,
    lastDayOfMonth,
    updateToPreviousMonth,
    updateToNextMonth,
  } = useDisplayDate(dateArg);

  const { mealsForCalender, fetchMealsLoading, refetchMealsForCalender } =
    useMeal({
      fetchMealsParams: {
        fetchMealsForCalenderParams: {
          requireFetchedData: true,
          startDate: firstDayOfMonth,
          lastDate: lastDayOfMonth,
        },
      },
    });

  const weekdays = [
    DAY_OF_SUNDAY,
    DAY_OF_MONDAY,
    DAY_OF_TUESDAY,
    DAY_OF_WEDNESDAY,
    DAY_OF_THURSDAY,
    DAY_OF_FRIDAY,
    DAY_OF_SATURDAY,
  ];
  const dateMealsList: { date: Date; dayLabel: string; meals: any[] }[] =
    (() => {
      return eachDayOfInterval({
        start: firstDayOfMonth,
        end: lastDayOfMonth,
      }).map((date) => {
        const meals =
          mealsForCalender?.find((mealForCalender) => {
            return isSameDay(new Date(mealForCalender.date), date);
          })?.meals || [];

        return {
          // なぜか9時間ずらさないとRailsに前日で送られるので暫定的に回避させる
          date: new Date(`${format(date, 'yyyy-MM-dd')}T09:00:00`),
          dayLabel: weekdays[getDay(date)],
          meals,
        };
      });
    })();

  return (
    <Calender
      dateMealsList={dateMealsList}
      fetchMealsLoading={fetchMealsLoading}
      refetchMealsForCalender={refetchMealsForCalender}
      refreshToPrev={updateToPreviousMonth}
      refreshToNext={updateToNextMonth}
    >
      {({ isDisplayCalenderMode, useAssignDishModeResult }) => (
        <>
          <div className={style['calender-header-title']}>
            {format(firstDayOfMonth, 'yyyy年M月')}
          </div>
          {/* &nbsp; */}
          {/* 今週(枠で括う) */}
          <div className={style['calender-header-menu']}>
            {isDisplayCalenderMode && (
              <CalenderMenu useAssignDishModeResult={useAssignDishModeResult} />
            )}
          </div>
        </>
      )}
    </Calender>
  );
};
