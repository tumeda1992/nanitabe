import { useCallback, useMemo } from 'react';
import {
  previousSunday,
  subDays,
  addDays,
  previousSaturday,
  previousMonday,
} from 'date-fns';
import { weekCalenderPagePathOf } from '../../../app/calender/week/[date]/consts';
import {
  DAY_OF_FRIDAY,
  DAY_OF_MONDAY,
  DAY_OF_SATURDAY,
  DAY_OF_SUNDAY,
  DAY_OF_THURSDAY,
  DAY_OF_TUESDAY,
  DAY_OF_WEDNESDAY,
} from '../calenderComponents/useCalenderDay';
import { useLogicalHistory } from '../../../app/logical-history';

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

export const useFirstDisplayDate = (
  specifiedDate: Date,
  getWeekStartDateFrom: (date: Date) => Date,
) => {
  const { pushHistory } = useLogicalHistory();

  const firstDisplayDate = useMemo(
    () => getWeekStartDateFrom(specifiedDate),
    [specifiedDate, getWeekStartDateFrom],
  );

  const reflectDate = useCallback(
    (date: Date) => {
      pushHistory(weekCalenderPagePathOf(date));
    },
    [pushHistory],
  );

  const updateFirstDateToPreviousWeekFirstDate = useCallback(() => {
    reflectDate(subDays(firstDisplayDate, 7));
  }, [firstDisplayDate, reflectDate]);

  const updateFirstDateToNextWeekFirstDate = useCallback(() => {
    reflectDate(addDays(firstDisplayDate, 7));
  }, [firstDisplayDate, reflectDate]);

  return {
    firstDisplayDate,
    updateFirstDateToPreviousWeekFirstDate,
    updateFirstDateToNextWeekFirstDate,
  };
};
