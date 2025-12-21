import { formatISO } from 'date-fns';

export const MONTH_CALENDER_PAGE_PATH = '/calender/month';
export const MONTH_CALENDER_PAGE_PATH_OF_THIS_MONTH =
  '/calender/month/thismonth';
export const monthCalenderPagePathOf = (date: Date) => {
  const dateString = formatISO(date, { representation: 'date' });
  return `${MONTH_CALENDER_PAGE_PATH}/${dateString}`;
};
export const isMonthPath = (path: string | null) => {
  if (!path) return false;
  const matched = path.match(new RegExp(`${MONTH_CALENDER_PAGE_PATH}/(.*)`));
  return !!matched;
};
