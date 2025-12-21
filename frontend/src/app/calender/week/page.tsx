import { permanentRedirect } from 'next/navigation';

import { WEEK_CALENDER_PAGE_PATH_OF_THIS_WEEK } from './[date]/consts';

export default (props) => {
  permanentRedirect(WEEK_CALENDER_PAGE_PATH_OF_THIS_WEEK);
};
