import { format } from 'date-fns';
import { isISODateFormatString } from '../utils/dateUtils';

export const calendarDateFromPath = (
  path: string,
  calendarPagePath: string,
  now = new Date(),
): Date => {
  const pathname = path.split(/[?#]/, 1)[0];
  const prefix = `${calendarPagePath}/`;
  const dateString = pathname.startsWith(prefix)
    ? pathname.slice(prefix.length)
    : null;

  if (dateString && isISODateFormatString(dateString)) {
    const date = new Date(`${dateString}T09:00:00`);
    const [year, month, day] = dateString.split('-').map(Number);
    if (
      date.getFullYear() === year &&
      date.getMonth() + 1 === month &&
      date.getDate() === day
    ) return date;
  }

  return new Date(`${format(now, 'yyyy-MM-dd')}T09:00:00`);
};
