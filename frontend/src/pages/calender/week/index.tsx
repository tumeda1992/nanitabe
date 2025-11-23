import { GetServerSideProps } from 'next';
import { WEEK_CALENDER_PAGE_URL_OF_THIS_WEEK } from './[date]';

export const getServerSideProps: GetServerSideProps = async () => {
  return {
    redirect: {
      permanent: true,
      destination: WEEK_CALENDER_PAGE_URL_OF_THIS_WEEK,
    },
  };
};

export default (props) => {
  return <div />;
};
