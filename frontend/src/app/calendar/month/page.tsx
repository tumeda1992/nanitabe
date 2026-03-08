import { permanentRedirect } from 'next/navigation';

import { MONTH_CALENDAR_PAGE_PATH_OF_THIS_MONTH } from './[date]/consts';

export default (props) => {
  permanentRedirect(MONTH_CALENDAR_PAGE_PATH_OF_THIS_MONTH);
};
