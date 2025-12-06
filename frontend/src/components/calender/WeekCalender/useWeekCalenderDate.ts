import { useState } from 'react';
import {
  previousSunday,
  subDays,
  addDays,
  previousSaturday,
  previousMonday,
} from 'date-fns';
import { useRouter, useParams } from 'next/navigation';
import { weekCalenderPageUrlOf } from '../../../app/calender/week/[date]/consts';
import { isISODateFormatString } from '../../../features/utils/dateUtils';
import {
  DAY_OF_FRIDAY,
  DAY_OF_MONDAY,
  DAY_OF_SATURDAY,
  DAY_OF_SUNDAY,
  DAY_OF_THURSDAY,
  DAY_OF_TUESDAY,
  DAY_OF_WEDNESDAY,
} from '../calenderComponents/useCalenderDay';

export const START_FROM_SAT = 'START_FROM_SAT';
export const START_FROM_SUN = 'START_FROM_SUN';
export const START_FROM_MON = 'START_FROM_MON';
type StartFromValue =
  | typeof START_FROM_SAT
  | typeof START_FROM_SUN
  | typeof START_FROM_MON;

const LIST_PER_START_DAY_OF_DAYS_OF_WEEK = {
  [START_FROM_SAT]: [
    { label: DAY_OF_SATURDAY },
    { label: DAY_OF_SUNDAY },
    { label: DAY_OF_MONDAY },
    { label: DAY_OF_TUESDAY },
    { label: DAY_OF_WEDNESDAY },
    { label: DAY_OF_THURSDAY },
    { label: DAY_OF_FRIDAY },
  ],
  [START_FROM_SUN]: [
    { label: DAY_OF_SUNDAY },
    { label: DAY_OF_MONDAY },
    { label: DAY_OF_TUESDAY },
    { label: DAY_OF_WEDNESDAY },
    { label: DAY_OF_THURSDAY },
    { label: DAY_OF_FRIDAY },
    { label: DAY_OF_SATURDAY },
  ],
  [START_FROM_MON]: [
    { label: DAY_OF_MONDAY },
    { label: DAY_OF_TUESDAY },
    { label: DAY_OF_WEDNESDAY },
    { label: DAY_OF_THURSDAY },
    { label: DAY_OF_FRIDAY },
    { label: DAY_OF_SATURDAY },
    { label: DAY_OF_SUNDAY },
  ],
};

export const useCalenderDayOfWeek = (startFromValue: StartFromValue) => {
  const getWeekStartDateFrom: (date: Date) => Date = (() => {
    if (startFromValue === START_FROM_SAT) {
      return (date: Date) => {
        const dayOfWeekNum = date.getDay();
        if (dayOfWeekNum === 6) return date;
        return previousSaturday(date);
      };
    }
    if (startFromValue === START_FROM_SUN) {
      return (date: Date) => {
        const dayOfWeekNum = date.getDay();
        if (dayOfWeekNum === 0) return date;
        return previousSunday(date);
      };
    }

    if (startFromValue === START_FROM_MON) {
      return (date: Date) => {
        const dayOfWeekNum = date.getDay();
        if (dayOfWeekNum === 1) return date;
        return previousMonday(date);
      };
    }

    return (date: Date) => date;
  })();

  return {
    daysOfWeek: LIST_PER_START_DAY_OF_DAYS_OF_WEEK[startFromValue],
    getWeekStartDateFrom,
  };
};

const pushWeekToHistory = (date: Date) => {
  if (typeof window === 'undefined') return;

  const url = weekCalenderPageUrlOf(date);
  const iso = date.toISOString().slice(0, 10);

  window.history.pushState({ date: iso }, '', url);
};

export const useFirstDisplayDate = (
  specifiedDate: Date,
  getWeekStartDateFrom: (date: Date) => Date,
) => {
  const [firstDisplayDate, setFirstDisplayDate] = useState(() =>
    getWeekStartDateFrom(specifiedDate),
  );

  const updateFirstDateToPreviousWeekFirstDate = () => {
    const previous = subDays(firstDisplayDate, 7);
    setFirstDisplayDate(previous);
    pushWeekToHistory(previous);
  };

  const updateFirstDateToNextWeekFirstDate = () => {
    const next = addDays(firstDisplayDate, 7);
    setFirstDisplayDate(next);
    pushWeekToHistory(next);
  };

  return {
    firstDisplayDate,
    updateFirstDateToPreviousWeekFirstDate,
    updateFirstDateToNextWeekFirstDate,
  };
};

export const useDateFormatStringInUrl = (
  extractDateStringFromUrl: (url: string) => string | null,
) => {
  const params = useParams<{ date?: string }>();

  const raw = params?.date ? params.date : '';

  const dateFormatString = isISODateFormatString(raw) ? raw : '';

  return { dateFormatString };
};
