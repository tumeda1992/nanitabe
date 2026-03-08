import { useState, useEffect, useCallback } from 'react';
import { subDays, addDays, startOfMonth, endOfMonth } from 'date-fns';
import { useLogicalHistory } from '../../../app/logical-history';
import { monthCalendarPagePathOf } from '../../../app/calendar/month/[date]/consts';

export const useDisplayDate = (specifiedDate: Date) => {
  const { pushHistory } = useLogicalHistory();

  const [firstDayOfMonth, setFirstDayOfMonth] = useState<Date>(() =>
    startOfMonth(specifiedDate),
  );
  const [lastDayOfMonth, setLastDayOfMonth] = useState<Date>(() =>
    endOfMonth(specifiedDate),
  );

  useEffect(() => {
    setFirstDayOfMonth(startOfMonth(specifiedDate));
    setLastDayOfMonth(endOfMonth(specifiedDate));
  }, [specifiedDate]);

  const reflectDate = useCallback((date: Date) => {
    setFirstDayOfMonth(startOfMonth(date));
    setLastDayOfMonth(endOfMonth(date));
    pushHistory(monthCalendarPagePathOf(startOfMonth(date)));
  }, []);

  const updateToPreviousMonth = useCallback(() => {
    reflectDate(subDays(firstDayOfMonth, 1));
  }, [firstDayOfMonth]);

  const updateToNextMonth = useCallback(() => {
    reflectDate(addDays(lastDayOfMonth, 1));
  }, [lastDayOfMonth]);

  return {
    firstDayOfMonth,
    lastDayOfMonth,
    updateToPreviousMonth,
    updateToNextMonth,
  };
};
