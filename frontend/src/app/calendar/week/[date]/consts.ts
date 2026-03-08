import { formatISO } from 'date-fns';

export const WEEK_CALENDAR_PAGE_PATH = '/calendar/week';
export const WEEK_CALENDAR_PAGE_PATH_OF_THIS_WEEK = '/calendar/week/thisweek';
export const weekCalendarPagePathOf = (date: Date) => {
  const dateString = formatISO(date, { representation: 'date' });
  return `${WEEK_CALENDAR_PAGE_PATH}/${dateString}`;
};
