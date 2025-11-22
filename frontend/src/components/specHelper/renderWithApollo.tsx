import {
  ApolloClient,
  InMemoryCache,
} from '@apollo/client';
import { HttpLink } from '@apollo/client/link/http';
import { ApolloProvider } from '@apollo/client/react';
import fetch from 'isomorphic-unfetch';
import React from 'react';
import { render } from '@testing-library/react';

const client = new ApolloClient({
  ssrMode: false,
  link: new HttpLink({
    uri: 'http://localhost',
    credentials: 'same-origin',
    /*
      https://github.com/facebook/jest/issues/10662#issuecomment-1417615125
      記載の通り、isomorphic-unfetchが4系だとjest実行時にSegmentation faultエラーが出るので、3系に下げた
     */
    fetch,
  }),
  cache: new InMemoryCache(),
});

export default (component: React.ReactNode) => {
  render(<ApolloProvider client={client}>{component}</ApolloProvider>);
};
