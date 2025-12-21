'use client';

import React from 'react';
import { format } from 'date-fns';
import WeekCalender from '../../../../components/calender/WeekCalender';
import { isISODateFormatString } from '../../../../features/utils/dateUtils';
import { WEEK_CALENDER_PAGE_PATH } from './consts';
import { useLogicalHistory } from '../../../logical-history';

const extractDateStringFromCalenderWeekPath = (path: string) => {
  if (!path) return null;
  const matched = path.match(new RegExp(`${WEEK_CALENDER_PAGE_PATH}/(.*)`));
  if (!matched) return null;

  const matchedDateString = matched[1];
  if (!isISODateFormatString(matchedDateString)) return null;

  return matchedDateString;
};

export default () => {
  const { currentPathAndQuery } = useLogicalHistory();
  const dateFormatString =
    extractDateStringFromCalenderWeekPath(currentPathAndQuery);

  if (!dateFormatString) {
    return (
      <WeekCalender
        date={new Date(`${format(new Date(), 'yyyy-MM-dd')}T09:00:00`)}
      />
    );
  }
  return <WeekCalender date={new Date(`${dateFormatString}T09:00:00`)} />;
};
