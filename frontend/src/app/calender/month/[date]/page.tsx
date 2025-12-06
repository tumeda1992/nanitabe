'use client';

import React from 'react';
import MonthCalender from '../../../../components/calender/MonthCalender';
import { isISODateFormatString } from '../../../../features/utils/dateUtils';
import { MONTH_CALENDER_PAGE_URL } from './consts';
import { useLogicalHistory } from '../../../logical-history';

const extractDateStringFromCalenderMonthUrl = (url: string) => {
  if (!url) return null;
  const matched = url.match(new RegExp(`${MONTH_CALENDER_PAGE_URL}/(.*)`));
  if (!matched) return null;

  const matchedDateString = matched[1];
  if (!isISODateFormatString(matchedDateString)) return null;

  return matchedDateString;
};

export default () => {
  const { currentPathAndQuery } = useLogicalHistory();
  const dateFormatString =
    extractDateStringFromCalenderMonthUrl(currentPathAndQuery);

  if (!dateFormatString) {
    return <MonthCalender />;
  }
  return <MonthCalender date={new Date(`${dateFormatString}T09:00:00`)} />;
};
