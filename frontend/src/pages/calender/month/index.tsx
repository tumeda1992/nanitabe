import { GetServerSideProps } from 'next';
import { MONTH_CALENDER_PAGE_URL_OF_THIS_MONTH } from './[date]';

export const getServerSideProps: GetServerSideProps = async () => {
  return {
    redirect: {
      permanent: true,
      destination: MONTH_CALENDER_PAGE_URL_OF_THIS_MONTH,
    },
  };
};

export default (props) => {
  return <div />;
};
