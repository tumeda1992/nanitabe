import { useMemo } from 'react';
import {
  ApolloClient,
  HttpLink,
  InMemoryCache,
  ApolloLink,
  // CombinedGraphQLErrors,
  // ServerError,
} from '@apollo/client';
import { ApolloServerErrorCode } from '@apollo/server/errors';
import { onError } from '@apollo/client/link/error';
// import { ErrorLink } from '@apollo/client/link/error';
import merge from 'deepmerge';
import isEqual from 'lodash/isEqual';
import fetch from 'isomorphic-unfetch';
import judgeExecInClientOrServer, {
  ExecSituation,
} from '../judgeExecInClientOrServer';
import {
  getAccessToken,
  setAccessToken,
} from '../../features/auth/accessTokenAccesser';
import { apiErrors } from './globalVars';

export const APOLLO_STATE_PROP_NAME = '__APOLLO_STATE__';

let apolloClient;
// 4系にあげたときの書き方
// const errorLink = new ErrorLink(({ error, result }) => {
//   if (CombinedGraphQLErrors.is(error)) {
//     error.errors.forEach(({ message }) => {
//       console.log(`GraphQL error: ${message}`);
//
//       // client 3.1.4の時代の書き方
//       // const { message, locations, path, extensions } = error;
//       //
//       // // TODO: インプット不正のときに無限リクエストが発生してしまう件を対処したかったが諦める。そもそもcodeはundefinedだし、無理やりnullを返しても何も変わらない
//       // // if (
//       // //   extensions?.code === ApolloServerErrorCode.BAD_USER_INPUT ||
//       // //   extensions === undefined
//       // // ) {
//       // //   console.log(error);
//       // //   // throw error;
//       // //   return null;
//       // // }
//     });
//     apiErrors(error.errors as any[]);
//   } else if (ServerError.is(error)) {
//     console.log(`Server error: ${error.message}`);
//   } else if (error) {
//     console.log(`Other error: ${error.message}`);
//   }
// });

const errorLink = onError(({ graphQLErrors, networkError }) => {
  if (graphQLErrors) {
    graphQLErrors.forEach((error) => {
      const { message, locations, path, extensions } = error;

      // TODO: インプット不正のときに無限リクエストが発生してしまう件を対処したかったが諦める。そもそもcodeはundefinedだし、無理やりnullを返しても何も変わらない
      // if (
      //   extensions?.code === ApolloServerErrorCode.BAD_USER_INPUT ||
      //   extensions === undefined
      // ) {
      //   console.log(error);
      //   // throw error;
      //   return null;
      // }

      console.log(
        `[GraphQL error]: Message: ${message}, Location: ${locations}, Path: ${path}`,
      );
    });
    // @ts-ignore
    apiErrors(graphQLErrors.map((error) => error));
  }
  if (networkError) console.log(`[Network error]: ${networkError}`);
});

const generateURL: () => string = () => {
  const apiOrigin: string = (() => {
    switch (judgeExecInClientOrServer) {
      case ExecSituation.ExecInServerSide:
        if (process.env.NEXT_PUBLIC_ENVIRONMENT === 'development') {
          return process.env.SERVER_SIDE_ORIGIN as string;
        }
        return process.env.NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN as string;
      case ExecSituation.ExecInClientSide:
        if (process.env.NEXT_PUBLIC_ENVIRONMENT === 'development') {
          return process.env.NEXT_PUBLIC_CLIENT_SIDE_DEV_ORIGIN as string;
        }
        return process.env.NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN as string;
      default:
        return '';
    }
  })();
  return `${apiOrigin}/graphql`;
};

const httpLink = new HttpLink({
  uri: generateURL(),
  fetch, // 4系を使うとテスト時にエラーになる都合で、3系に落としている(20230321時点)
});

const buildAuthLink = (nextJsContext = null) => {
  const accessToken = getAccessToken(nextJsContext);

  return new ApolloLink((operation, forward) => {
    operation.setContext(({ headers = {} }) => ({
      headers: {
        ...headers,
        Authorization: accessToken || '',
      },
    }));

    return forward(operation);
  });
};

const afterwareLink = new ApolloLink((operation, forward) => {
  return forward(operation).map((response) => {
    const context = operation.getContext();
    const { headers } = context.response;
    const accessToken = headers?.get('authorization');

    if (accessToken) {
      setAccessToken(accessToken);
    }

    return response;
  });
});

function buildApolloClient(nextJsContext = null) {
  const _apolloClient = new ApolloClient({
    ssrMode: typeof window === 'undefined',
    link: ApolloLink.from([
      buildAuthLink(nextJsContext),
      afterwareLink,
      errorLink,
      httpLink,
    ]),
    cache: new InMemoryCache(),
  });
  if (!apolloClient) apolloClient = _apolloClient;

  return _apolloClient;
}

export const useApolloClient = () => {
  return { apolloClient };
};

function initializeApollo(initialState = null) {
  const _apolloClient = apolloClient ?? buildApolloClient();

  // If your page has Next.js data fetching methods that use Apollo Client, the initial state
  // gets hydrated here
  if (initialState) {
    // Get existing cache, loaded during client side data fetching
    const existingCache = _apolloClient.extract();

    // Merge the initialState from getStaticProps/getServerSideProps in the existing cache
    const data = merge(existingCache, initialState, {
      // combine arrays using object equality (like in sets)
      arrayMerge: (destinationArray, sourceArray) => [
        ...sourceArray,
        ...destinationArray.filter((d) =>
          sourceArray.every((s) => !isEqual(d, s)),
        ),
      ],
    });

    // Restore the cache with the merged data
    _apolloClient.cache.restore(data);
  }
  // For SSG and SSR always create a new Apollo Client
  if (typeof window === 'undefined') return _apolloClient;
  // Create the Apollo Client once in the client
  if (!apolloClient) apolloClient = _apolloClient;

  return _apolloClient;
}

export function addApolloState(client, pageProps) {
  if (pageProps?.props) {
    pageProps.props[APOLLO_STATE_PROP_NAME] = client.cache.extract();
  }

  return pageProps;
}

export function useApollo(pageProps) {
  const state = pageProps[APOLLO_STATE_PROP_NAME];
  const store = useMemo(() => initializeApollo(state), [state]);
  return store;
}

export default buildApolloClient;
