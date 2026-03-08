import { permanentRedirect } from 'next/navigation';

export default () => {
  permanentRedirect('/calendar/week/thisweek');
};
