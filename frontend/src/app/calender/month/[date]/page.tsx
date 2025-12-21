'use client';

import React from 'react';
import { format } from 'date-fns';
import MonthCalender from '../../../../components/calender/MonthCalender';
import { isISODateFormatString } from '../../../../features/utils/dateUtils';
import { MONTH_CALENDER_PAGE_PATH } from './consts';
import { useLogicalHistory } from '../../../logical-history';

const extractDateStringFromCalenderMonthPath = (path: string) => {
  if (!path) return null;
  const matched = path.match(new RegExp(`${MONTH_CALENDER_PAGE_PATH}/(.*)`));
  if (!matched) return null;

  const matchedDateString = matched[1];
  if (!isISODateFormatString(matchedDateString)) return null;

  return matchedDateString;
};

export default () => {
  const { currentPathAndQuery } = useLogicalHistory();
  const dateFormatString =
    extractDateStringFromCalenderMonthPath(currentPathAndQuery);

  if (!dateFormatString) {
    return (
      <MonthCalender
        date={new Date(`${format(new Date(), 'yyyy-MM-dd')}T09:00:00`)}
      />
    );
  }
  return <MonthCalender date={new Date(`${dateFormatString}T09:00:00`)} />;
};
