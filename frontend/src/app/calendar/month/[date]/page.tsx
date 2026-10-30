'use client';

import React from 'react';
import MonthCalendar from '../../../../components/calendar/MonthCalendar';
import { calendarDateFromPath } from '../../../../features/calendar/calendarDateFromPath';
import { MONTH_CALENDAR_PAGE_PATH } from './consts';
import { useLogicalHistory } from '../../../logical-history';

export default () => {
  const { currentPathAndQuery } = useLogicalHistory();
  return (
    <MonthCalendar
      date={calendarDateFromPath(currentPathAndQuery, MONTH_CALENDAR_PAGE_PATH)}
    />
  );
};
