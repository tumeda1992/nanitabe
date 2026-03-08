'use client';

import React from 'react';
import { format } from 'date-fns';
import MonthCalendar from '../../../../components/calendar/MonthCalendar';
import { isISODateFormatString } from '../../../../features/utils/dateUtils';
import { MONTH_CALENDAR_PAGE_PATH } from './consts';
import { useLogicalHistory } from '../../../logical-history';

const extractDateStringFromCalendarMonthPath = (path: string) => {
  if (!path) return null;
  const matched = path.match(new RegExp(`${MONTH_CALENDAR_PAGE_PATH}/(.*)`));
  if (!matched) return null;

  const matchedDateString = matched[1];
  if (!isISODateFormatString(matchedDateString)) return null;

  return matchedDateString;
};

export default () => {
  const { currentPathAndQuery } = useLogicalHistory();
  const dateFormatString =
    extractDateStringFromCalendarMonthPath(currentPathAndQuery);

  if (!dateFormatString) {
    return (
      <MonthCalendar
        date={new Date(`${format(new Date(), 'yyyy-MM-dd')}T09:00:00`)}
      />
    );
  }
  return <MonthCalendar date={new Date(`${dateFormatString}T09:00:00`)} />;
};
