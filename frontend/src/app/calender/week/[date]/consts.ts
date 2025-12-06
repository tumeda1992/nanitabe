import { formatISO } from 'date-fns';

export const WEEK_CALENDER_PAGE_PATH = '/calender/week';
export const WEEK_CALENDER_PAGE_PATH_OF_THIS_WEEK = '/calender/week/thisweek';
export const weekCalenderPagePathOf = (date: Date) => {
  const dateString = formatISO(date, { representation: 'date' });
  return `${WEEK_CALENDER_PAGE_PATH}/${dateString}`;
};
