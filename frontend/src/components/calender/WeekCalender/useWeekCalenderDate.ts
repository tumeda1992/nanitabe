import {
  previousSunday,
  subDays,
  addDays,
  previousSaturday,
  previousMonday,
} from 'date-fns';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import { weekCalenderPageUrlOf } from '../../../pages/calender/week/[date]';
import { isISODateFormatString } from '../../../features/utils/dateUtils';
import {
  DAY_OF_FRIDAY,
  DAY_OF_MONDAY,
  DAY_OF_SATURDAY,
  DAY_OF_SUNDAY,
  DAY_OF_THURSDAY,
  DAY_OF_TUESDAY,
  DAY_OF_WEDNESDAY,
} from '../calenderComponents/useCalenderDay';

export const START_FROM_SAT = 'START_FROM_SAT';
export const START_FROM_SUN = 'START_FROM_SUN';
export const START_FROM_MON = 'START_FROM_MON';
type StartFromValue =
  | typeof START_FROM_SAT
  | typeof START_FROM_SUN
  | typeof START_FROM_MON;

const LIST_PER_START_DAY_OF_DAYS_OF_WEEK = {
  [START_FROM_SAT]: [
    { label: DAY_OF_SATURDAY },
    { label: DAY_OF_SUNDAY },
    { label: DAY_OF_MONDAY },
    { label: DAY_OF_TUESDAY },
    { label: DAY_OF_WEDNESDAY },
    { label: DAY_OF_THURSDAY },
    { label: DAY_OF_FRIDAY },
  ],
  [START_FROM_SUN]: [
    { label: DAY_OF_SUNDAY },
    { label: DAY_OF_MONDAY },
    { label: DAY_OF_TUESDAY },
    { label: DAY_OF_WEDNESDAY },
    { label: DAY_OF_THURSDAY },
    { label: DAY_OF_FRIDAY },
    { label: DAY_OF_SATURDAY },
  ],
  [START_FROM_MON]: [
    { label: DAY_OF_MONDAY },
    { label: DAY_OF_TUESDAY },
    { label: DAY_OF_WEDNESDAY },
    { label: DAY_OF_THURSDAY },
    { label: DAY_OF_FRIDAY },
    { label: DAY_OF_SATURDAY },
    { label: DAY_OF_SUNDAY },
  ],
};

export const useCalenderDayOfWeek = (startFromValue: StartFromValue) => {
  const getWeekStartDateFrom = (() => {
    if (startFromValue === START_FROM_SAT) {
      return (date: Date) => {
        const dayOfWeekNum = date.getDay();
        if (dayOfWeekNum === 6) return date;
        return previousSaturday(date);
      };
    }
    if (startFromValue === START_FROM_SUN) {
      return (date: Date) => {
        const dayOfWeekNum = date.getDay();
        if (dayOfWeekNum === 0) return date;
        return previousSunday(date);
      };
    }

    if (startFromValue === START_FROM_MON) {
      return (date: Date) => {
        const dayOfWeekNum = date.getDay();
        if (dayOfWeekNum === 1) return date;
        return previousMonday(date);
      };
    }
  })();

  return {
    daysOfWeek: LIST_PER_START_DAY_OF_DAYS_OF_WEEK[startFromValue],
    getWeekStartDateFrom,
  };
};

export const useFirstDisplayDate = (
  specifiedDate: Date,
  getWeekStartDateFrom,
) => {
  const firstDisplayDate = getWeekStartDateFrom(specifiedDate);

  /*
    NOTE: 日付変更方針: URLを正として、コンポーネントはそれに追随し、更新したい場合はURLを更新する
    - 初めにコンポーネントで閉じるstateで日付を管理していた
      - router.pushで日付更新した後の「戻る」で戻った後の日付反映できなかった。
    - 次にページコンポーネントでもstateを持って、このhooksを使うコンポーネントでもstateを持った
      - 管理の側面でも二重管理になっていた
      - 片方を変えたときに、もう一方が意図せず変わるなどが起きてしまった
    - 最終的に不服だが、コンポーネントに閉じずにページコンポーネントで扱うURLに追随するようにした
   */
  const router = useRouter();

  const updateFirstDateToPreviousWeekFirstDate = () => {
    router.push(weekCalenderPageUrlOf(subDays(firstDisplayDate, 7)));
  };

  const updateFirstDateToNextWeekFirstDate = () => {
    router.push(weekCalenderPageUrlOf(addDays(firstDisplayDate, 7)));
  };

  return {
    firstDisplayDate,
    updateFirstDateToPreviousWeekFirstDate,
    updateFirstDateToNextWeekFirstDate,
  };
};

export const useDateFormatStringInUrl = (
  extractDateStringFromUrl: (url: string) => string | null,
) => {
  const router = useRouter();
  const [dateFormatString, setDateFormatString] = useState(
    router.query.date as string,
  );

  // router.pushによるURL更新や「戻る/次へ」によるURL変更への追随
  useEffect(() => {
    const handleChangedUrl = (changedUrl: string) => {
      const dateStringOfNewUrl = extractDateStringFromUrl(changedUrl);
      if (isISODateFormatString(dateStringOfNewUrl)) {
        setDateFormatString(dateStringOfNewUrl);
      } else {
        setDateFormatString('');
      }
    };

    router.beforePopState(({ as }) => {
      handleChangedUrl(as);
      return true;
    });

    const handleRouteChange = (url) => {
      handleChangedUrl(url);
    };
    router.events.on('routeChangeStart', handleRouteChange);
    return () => {
      router.events.off('routeChangeStart', handleRouteChange);
    };
  }, [router]);

  return { dateFormatString };
};
