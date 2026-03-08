import { permanentRedirect } from 'next/navigation';

export default (props) => {
  permanentRedirect('/calendar/week/thisweek');
};
