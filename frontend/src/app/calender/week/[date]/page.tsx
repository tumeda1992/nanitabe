'use client';

import React from 'react';
import WeekCalender, {
  useDateFormatStringInUrl,
} from '../../../../components/calender/WeekCalender';
import { isISODateFormatString } from '../../../../features/utils/dateUtils';
import { WEEK_CALENDER_PAGE_URL } from './consts';

const extractDateStringFromCalenderWeekUrl = (url: string) => {
  const matched = url.match(new RegExp(`${WEEK_CALENDER_PAGE_URL}/(.*)`));
  if (!matched) return null;
  return matched[1];
};

export default () => {
  const { dateFormatString } = useDateFormatStringInUrl(
    extractDateStringFromCalenderWeekUrl,
  );

  if (!isISODateFormatString(dateFormatString)) {
    return <WeekCalender />;
  }
  return <WeekCalender date={new Date(`${dateFormatString}T09:00:00`)} />;
};
