import { permanentRedirect } from 'next/navigation';

export default () => {
  permanentRedirect('/calendar/month/thismonth');
};
