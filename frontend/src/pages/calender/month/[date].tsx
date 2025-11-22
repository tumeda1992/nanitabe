import React from 'react';
import { formatISO } from 'date-fns';
import MonthCalender, {
  useDateFormatStringInUrl,
} from '../../../components/calender/MonthCalender';
import { isISODateFormatString } from '../../../features/utils/dateUtils';

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
const extractDateStringFromCalenderMonthUrl = (url: string) => {
  if (!url) return null;
  const matched = url.match(new RegExp(`${MONTH_CALENDER_PAGE_URL}/(.*)`));
  if (!matched) return null;
  return matched[1];
};

export async function getServerSideProps(context) {
  return { props: {} };
}

export default (props) => {
  const { dateFormatString } = useDateFormatStringInUrl(
    extractDateStringFromCalenderMonthUrl,
  );

  if (!isISODateFormatString(dateFormatString)) {
    return <MonthCalender />;
  }
  return <MonthCalender date={new Date(`${dateFormatString}T09:00:00`)} />;
};
