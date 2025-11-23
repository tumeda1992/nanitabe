import { permanentRedirect } from 'next/navigation';

import { MONTH_CALENDER_PAGE_URL_OF_THIS_MONTH } from './[date]/consts';

export default (props) => {
  permanentRedirect(MONTH_CALENDER_PAGE_URL_OF_THIS_MONTH);
};
