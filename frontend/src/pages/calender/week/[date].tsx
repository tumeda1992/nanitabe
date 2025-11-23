import React from 'react';
import { formatISO } from 'date-fns';
import WeekCalender, {
  useDateFormatStringInUrl,
} from '../../../components/calender/WeekCalender';
import { isISODateFormatString } from '../../../features/utils/dateUtils';

export const WEEK_CALENDER_PAGE_URL = '/calender/week';
export const WEEK_CALENDER_PAGE_URL_OF_THIS_WEEK = '/calender/week/thisweek';
export const weekCalenderPageUrlOf = (date: Date) => {
  const dateString = formatISO(date, { representation: 'date' });
  return `${WEEK_CALENDER_PAGE_URL}/${dateString}`;
};
const extractDateStringFromCalenderWeekUrl = (url: string) => {
  const matched = url.match(new RegExp(`${WEEK_CALENDER_PAGE_URL}/(.*)`));
  if (!matched) return null;
  return matched[1];
};

export async function getServerSideProps(context) {
  return { props: {} };
}

export default (props) => {
  const { dateFormatString } = useDateFormatStringInUrl(
    extractDateStringFromCalenderWeekUrl,
  );

  if (!isISODateFormatString(dateFormatString)) {
    return <WeekCalender />;
  }
  return <WeekCalender date={new Date(`${dateFormatString}T09:00:00`)} />;
};
