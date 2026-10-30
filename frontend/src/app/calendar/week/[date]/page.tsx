'use client';

import React from 'react';
import WeekCalendar from '../../../../components/calendar/WeekCalendar';
import { calendarDateFromPath } from '../../../../features/calendar/calendarDateFromPath';
import { WEEK_CALENDAR_PAGE_PATH } from './consts';
import { useLogicalHistory } from '../../../logical-history';

export default () => {
  const { currentPathAndQuery } = useLogicalHistory();
  return (
    <WeekCalendar
      date={calendarDateFromPath(currentPathAndQuery, WEEK_CALENDAR_PAGE_PATH)}
    />
  );
};
