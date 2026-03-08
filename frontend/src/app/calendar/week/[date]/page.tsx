'use client';

import React from 'react';
import { format } from 'date-fns';
import WeekCalendar from '../../../../components/calendar/WeekCalendar';
import { isISODateFormatString } from '../../../../features/utils/dateUtils';
import { WEEK_CALENDAR_PAGE_PATH } from './consts';
import { useLogicalHistory } from '../../../logical-history';

const extractDateStringFromCalendarWeekPath = (path: string) => {
  if (!path) return null;
  const matched = path.match(new RegExp(`${WEEK_CALENDAR_PAGE_PATH}/(.*)`));
  if (!matched) return null;

  const matchedDateString = matched[1];
  if (!isISODateFormatString(matchedDateString)) return null;

  return matchedDateString;
};

export default () => {
  const { currentPathAndQuery } = useLogicalHistory();
  const dateFormatString =
    extractDateStringFromCalendarWeekPath(currentPathAndQuery);

  if (!dateFormatString) {
    return (
      <WeekCalendar
        date={new Date(`${format(new Date(), 'yyyy-MM-dd')}T09:00:00`)}
      />
    );
  }
  return <WeekCalendar date={new Date(`${dateFormatString}T09:00:00`)} />;
};
