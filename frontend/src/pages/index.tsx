import { gql } from '@apollo/client';
import type { GetServerSideProps, GetServerSidePropsContext } from 'next';
import buildApolloClient, {
  addApolloState,
} from '../lib/graphql/buildApolloClient';
import { WEEK_CALENDER_PAGE_URL_OF_THIS_WEEK } from './calender/week/[date]';

const IndexPage = (props) => {
  // const { hogehoge } = props;
  // console.log(hogehoge);

  const apolloClient = buildApolloClient();
  const query = gql`
    {
      testField
    }
  `;
  apolloClient
    .query({
      query,
    })
    .then((result) => console.log(result));
  return <>index</>;
};

// export const getServerSideProps: GetServerSideProps = async (
//   context: GetServerSidePropsContext,
// ) => {
//   const apolloClient = buildApolloClient(context);
//
//   const query = gql`
//     {
//       testField
//     }
//   `;
//   const hogehoge = await apolloClient.query({
//     query,
//   });
//
//   return addApolloState(apolloClient, {
//     props: { hogehoge },
//   });
// };

export const getServerSideProps: GetServerSideProps = async () => {
  return {
    redirect: {
      permanent: true,
      destination: WEEK_CALENDER_PAGE_URL_OF_THIS_WEEK,
    },
  };
};

export default IndexPage;
