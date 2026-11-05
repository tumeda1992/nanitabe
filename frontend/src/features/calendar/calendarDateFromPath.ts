import { format } from 'date-fns';
import { isISODateFormatString } from '../utils/dateUtils';

export const calendarDateFromPath = (
  path: string,
  calendarPagePath: string,
  now = new Date(),
): Date => {
  const matched = path && path.match(new RegExp(`${calendarPagePath}/(.*)`));
  const matchedDateString = matched ? matched[1] : null;
  const dateString = isISODateFormatString(matchedDateString)
    ? matchedDateString
    : format(now, 'yyyy-MM-dd');

  return new Date(`${dateString}T09:00:00`);
};
