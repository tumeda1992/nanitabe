'use client';

import React from 'react';
import WeekCalender, {
  useDateFormatStringInUrl,
} from '../../../../components/calender/WeekCalender';
import { isISODateFormatString } from '../../../../features/utils/dateUtils';
import { WEEK_CALENDER_PAGE_URL } from './consts';
import { useLogicalHistory } from '../../../logical-history';

// TODO: URLという言葉をpathとかpathAndQueryに変更する
const extractDateStringFromCalenderWeekUrl = (url: string) => {
  const matched = url.match(new RegExp(`${WEEK_CALENDER_PAGE_URL}/(.*)`));
  if (!matched) return null;

  const matchedDateString = matched[1];
  if (!isISODateFormatString(matchedDateString)) return null;

  return matchedDateString;
};

export default () => {
  const { currentPathAndQuery } = useLogicalHistory();
  const dateFormatString =
    extractDateStringFromCalenderWeekUrl(currentPathAndQuery);

  if (!dateFormatString) {
    return <WeekCalender />;
  }
  return <WeekCalender date={new Date(`${dateFormatString}T09:00:00`)} />;
};
