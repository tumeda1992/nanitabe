'use client';

import React, { useMemo, useEffect, useState } from 'react';
import { addDays, format, isSameDay, subDays } from 'date-fns';
import Calendar from '../calendarComponents/Calendar';
import useMeal from '../../../features/meal/useMeal';
import {
  START_FROM_SAT,
  useCalendarDayOfWeek,
  useFirstDisplayDate,
} from './useWeekCalendarDate';
import CalendarHeader from '../calendarComponents/CalendarHeader';

export type Props = {
  date: Date;
};

export default (props: Props) => {
  const { date: dateArg } = props;
  // TODO: 自分以外も使うようになったらユーザ設定で選べるようにする
  const { daysOfWeek, getWeekStartDateFrom } =
    useCalendarDayOfWeek(START_FROM_SAT);
  const {
    firstDisplayDate,
    updateFirstDateToPreviousWeekFirstDate,
    updateFirstDateToNextWeekFirstDate,
  } = useFirstDisplayDate(dateArg, getWeekStartDateFrom);

  const fetchMealsParams = useMemo(() => {
    return {
      fetchMealsParams: {
        fetchMealsForCalenderParams: {
          requireFetchedData: true,
          startDate: subDays(firstDisplayDate, 7),
          lastDate: addDays(firstDisplayDate, 6 + 7),
        },
      },
    };
  }, [firstDisplayDate]);

  const {
    mealsForCalender: mealsForCalendar,
    fetchMealsLoading,
    refetchMealsForCalender: refetchMealsForCalendar,
  } = useMeal(fetchMealsParams);

  // 多分GraphQLクライアント(apollo)のキャッシュでなんとかしたほうがいいやつ
  const [cachedMeals, setCachedMeals] = useState([]);
  useEffect(() => {
    if (mealsForCalendar && !fetchMealsLoading) {
      setCachedMeals(mealsForCalendar);
    }
  }, [mealsForCalendar]);

  const dateMealsList: { date: Date; dayLabel: string; meals: any[]; frameEntries: any[] }[] =
    (() => {
      return daysOfWeek.map((day, dayIndex) => {
        const date = addDays(firstDisplayDate, Number(dayIndex));
        const calendarEntry = (mealsForCalendar || cachedMeals)?.find((mealForCalendar) => {
          return isSameDay(new Date(mealForCalendar.date), date);
        });
        const meals = calendarEntry?.meals || [];
        const frameEntries = calendarEntry?.frameEntries || [];
        return {
          date,
          dayLabel: day.label,
          meals,
          frameEntries,
        };
      });
    })();

  const weekEndDate = addDays(firstDisplayDate, 6);
  const displayLabel = `${format(firstDisplayDate, 'M/d')} - ${format(weekEndDate, 'M/d')}`;

  return (
    <Calendar
      dateMealsList={dateMealsList}
      fetchMealsLoading={fetchMealsLoading}
      refetchMealsForCalendar={refetchMealsForCalendar}
      refreshToPrev={updateFirstDateToPreviousWeekFirstDate}
      refreshToNext={updateFirstDateToNextWeekFirstDate}
    >
      {({ isDisplayCalendarMode, useAssignDishModeResult, refreshToPrev, refreshToNext }) => (
        <CalendarHeader
          viewType="week"
          displayLabel={displayLabel}
          currentDate={firstDisplayDate}
          refreshToPrev={refreshToPrev}
          refreshToNext={refreshToNext}
          isDisplayCalendarMode={isDisplayCalendarMode}
          onStartAssigningDish={useAssignDishModeResult.startAssigningDishMode}
        />
      )}
    </Calendar>
  );
};
