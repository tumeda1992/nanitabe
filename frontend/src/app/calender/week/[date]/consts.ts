import { formatISO } from 'date-fns';

export const WEEK_CALENDER_PAGE_URL = '/calender/week';
export const WEEK_CALENDER_PAGE_URL_OF_THIS_WEEK = '/calender/week/thisweek';
export const weekCalenderPageUrlOf = (date: Date) => {
  const dateString = formatISO(date, { representation: 'date' });
  return `${WEEK_CALENDER_PAGE_URL}/${dateString}`;
};
