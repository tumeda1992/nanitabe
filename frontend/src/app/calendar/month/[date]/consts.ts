import { formatISO } from 'date-fns';

export const MONTH_CALENDAR_PAGE_PATH = '/calendar/month';
export const MONTH_CALENDAR_PAGE_PATH_OF_THIS_MONTH =
  '/calendar/month/thismonth';
export const monthCalendarPagePathOf = (date: Date) => {
  const dateString = formatISO(date, { representation: 'date' });
  return `${MONTH_CALENDAR_PAGE_PATH}/${dateString}`;
};
export const isMonthPath = (path: string | null) => {
  if (!path) return false;
  const matched = path.match(new RegExp(`${MONTH_CALENDAR_PAGE_PATH}/(.*)`));
  return !!matched;
};
