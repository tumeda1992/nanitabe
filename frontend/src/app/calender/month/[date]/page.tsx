'use client';

import React from 'react';
import MonthCalender, {
  useDateFormatStringInUrl,
} from '../../../../components/calender/MonthCalender';
import { isISODateFormatString } from '../../../../features/utils/dateUtils';
import { MONTH_CALENDER_PAGE_URL } from './consts';

const extractDateStringFromCalenderMonthUrl = (url: string) => {
  if (!url) return null;
  const matched = url.match(new RegExp(`${MONTH_CALENDER_PAGE_URL}/(.*)`));
  if (!matched) return null;
  return matched[1];
};

export default (props) => {
  const { dateFormatString } = useDateFormatStringInUrl(
    extractDateStringFromCalenderMonthUrl,
  );

  if (!isISODateFormatString(dateFormatString)) {
    return <MonthCalender />;
  }
  return <MonthCalender date={new Date(`${dateFormatString}T09:00:00`)} />;
};
