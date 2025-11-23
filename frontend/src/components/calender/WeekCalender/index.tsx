import React from 'react';
import { addDays, format, formatISO, isSameDay } from 'date-fns';
import Calender from '../calenderComponents/Calender';
import useMeal from '../../../features/meal/useMeal';
import {
  START_FROM_SAT,
  useCalenderDayOfWeek,
  useFirstDisplayDate,
} from './useWeekCalenderDate';
import style from '../calenderComponents/Calender/index.module.scss';
import CalenderMenu from './CalenderMenu';

export { useDateFormatStringInUrl } from './useWeekCalenderDate';

export type Props = {
  date?: Date;
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
  } = useFirstDisplayDate(dateArg || new Date(), getWeekStartDateFrom);

  const { mealsForCalender, fetchMealsLoading, refetchMealsForCalender } =
    useMeal({
      fetchMealsParams: {
        fetchMealsForCalenderParams: {
          requireFetchedData: true,
          startDate: firstDisplayDate,
          lastDate: addDays(firstDisplayDate, 6),
        },
      },
    });

  const dateMealsList: { date: Date; dayLabel: string; meals: any[] }[] =
    (() => {
      return daysOfWeek.map((day, dayIndex) => {
        const date = addDays(firstDisplayDate, Number(dayIndex));
        const meals =
          mealsForCalender?.find((mealForCalender) => {
            return isSameDay(new Date(mealForCalender.date), date);
          })?.meals || [];
        return {
          date,
          dayLabel: day.label,
          meals,
        };
      });
    })();

  return (
    <Calender
      dateMealsList={dateMealsList}
      fetchMealsLoading={fetchMealsLoading}
      refetchMealsForCalender={refetchMealsForCalender}
      refreshToPrev={updateFirstDateToPreviousWeekFirstDate}
      refreshToNext={updateFirstDateToNextWeekFirstDate}
    >
      {({ isDisplayCalenderMode, useAssignDishModeResult }) => (
        <>
          <div className={style['calender-header-title']}>
            {format(firstDisplayDate, 'yyyy年M月')}
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
