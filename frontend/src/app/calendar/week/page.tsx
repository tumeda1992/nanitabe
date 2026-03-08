import { permanentRedirect } from 'next/navigation';

import { WEEK_CALENDAR_PAGE_PATH_OF_THIS_WEEK } from './[date]/consts';

export default () => {
  permanentRedirect(WEEK_CALENDAR_PAGE_PATH_OF_THIS_WEEK);
};
