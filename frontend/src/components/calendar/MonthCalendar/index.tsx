'use client';

import React from 'react';
import {
  format,
  isSameDay,
  getDay,
  eachDayOfInterval,
} from 'date-fns';
import Calendar from '../calendarComponents/Calendar';
import useMeal from '../../../features/meal/useMeal';
import {
  DAY_OF_FRIDAY,
  DAY_OF_MONDAY,
  DAY_OF_SATURDAY,
  DAY_OF_SUNDAY,
  DAY_OF_THURSDAY,
  DAY_OF_TUESDAY,
  DAY_OF_WEDNESDAY,
} from '../calendarComponents/useCalendarDay';
import { useDisplayDate } from './useMonthCalendarDate';
import CalendarHeader from '../calendarComponents/CalendarHeader';

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

  const {
    mealsForCalender: mealsForCalendar,
    fetchMealsLoading,
    refetchMealsForCalender: refetchMealsForCalendar,
  } = useMeal({
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
          mealsForCalendar?.find((mealForCalendar) => {
            return isSameDay(new Date(mealForCalendar.date), date);
          })?.meals || [];

        return {
          // なぜか9時間ずらさないとRailsに前日で送られるので暫定的に回避させる
          date: new Date(`${format(date, 'yyyy-MM-dd')}T09:00:00`),
          dayLabel: weekdays[getDay(date)],
          meals,
        };
      });
    })();

  const displayLabel = format(firstDayOfMonth, 'yyyy年M月');

  return (
    <Calendar
      dateMealsList={dateMealsList}
      fetchMealsLoading={fetchMealsLoading}
      refetchMealsForCalendar={refetchMealsForCalendar}
      refreshToPrev={updateToPreviousMonth}
      refreshToNext={updateToNextMonth}
    >
      {({ isDisplayCalendarMode, useAssignDishModeResult, refreshToPrev, refreshToNext }) => (
        <CalendarHeader
          viewType="month"
          displayLabel={displayLabel}
          currentDate={firstDayOfMonth}
          refreshToPrev={refreshToPrev}
          refreshToNext={refreshToNext}
          isDisplayCalendarMode={isDisplayCalendarMode}
          onStartAssigningDish={useAssignDishModeResult.startAssigningDishMode}
        />
      )}
    </Calendar>
  );
};
