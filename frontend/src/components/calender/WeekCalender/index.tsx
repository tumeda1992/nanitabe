'use client';

import React, { useMemo, useEffect, useState } from 'react';
import { addDays, format, isSameDay, subDays } from 'date-fns';
import Calender from '../calenderComponents/Calender';
import useMeal from '../../../features/meal/useMeal';
import {
  START_FROM_SAT,
  useCalenderDayOfWeek,
  useFirstDisplayDate,
} from './useWeekCalenderDate';
import CalendarHeader from '../calenderComponents/CalendarHeader';

export type Props = {
  date: Date;
};

export default (props: Props) => {
  const { date: dateArg } = props;
  // TODO: 自分以外も使うようになったらユーザ設定で選べるようにする
  const { daysOfWeek, getWeekStartDateFrom } =
    useCalenderDayOfWeek(START_FROM_SAT);
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

  const { mealsForCalender, fetchMealsLoading, refetchMealsForCalender } =
    useMeal(fetchMealsParams);

  // 多分GraphQLクライアント(apollo)のキャッシュでなんとかしたほうがいいやつ
  const [cachedMeals, setCachedMeals] = useState([]);
  useEffect(() => {
    if (mealsForCalender && !fetchMealsLoading) {
      setCachedMeals(mealsForCalender);
    }
  }, [mealsForCalender]);

  const dateMealsList: { date: Date; dayLabel: string; meals: any[] }[] =
    (() => {
      return daysOfWeek.map((day, dayIndex) => {
        const date = addDays(firstDisplayDate, Number(dayIndex));
        const meals =
          (mealsForCalender || cachedMeals)?.find((mealForCalender) => {
            return isSameDay(new Date(mealForCalender.date), date);
          })?.meals || [];
        return {
          date,
          dayLabel: day.label,
          meals,
        };
      });
    })();

  const weekEndDate = addDays(firstDisplayDate, 6);
  const displayLabel = `${format(firstDisplayDate, 'M/d')} - ${format(weekEndDate, 'M/d')}`;

  return (
    <Calender
      dateMealsList={dateMealsList}
      fetchMealsLoading={fetchMealsLoading}
      refetchMealsForCalender={refetchMealsForCalender}
      refreshToPrev={updateFirstDateToPreviousWeekFirstDate}
      refreshToNext={updateFirstDateToNextWeekFirstDate}
    >
      {({ isDisplayCalenderMode, useAssignDishModeResult, refreshToPrev, refreshToNext }) => (
        <CalendarHeader
          viewType="week"
          displayLabel={displayLabel}
          currentDate={firstDisplayDate}
          refreshToPrev={refreshToPrev}
          refreshToNext={refreshToNext}
          isDisplayCalenderMode={isDisplayCalenderMode}
          onStartAssigningDish={useAssignDishModeResult.startAssigningDishMode}
        />
      )}
    </Calender>
  );
};
