import { formatISO } from 'date-fns';

// TODO: URLという言葉をpathとかpathAndQueryに変更する
export const MONTH_CALENDER_PAGE_URL = '/calender/month';
export const MONTH_CALENDER_PAGE_URL_OF_THIS_MONTH =
  '/calender/month/thismonth';
export const monthCalenderPageUrlOf = (date: Date) => {
  const dateString = formatISO(date, { representation: 'date' });
  return `${MONTH_CALENDER_PAGE_URL}/${dateString}`;
};
export const isMonthPath = (url: string | null) => {
  if (!url) return false;
  const matched = url.match(new RegExp(`${MONTH_CALENDER_PAGE_URL}/(.*)`));
  return !!matched;
};
