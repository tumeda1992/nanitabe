import React from 'react';
import { ApolloProvider } from '@apollo/client/react';
// import { useRouter } from 'next/router';
import type { AppProps } from 'next/app';
import { useApollo } from '../lib/graphql/buildApolloClient';
import 'bootstrap/dist/css/bootstrap.min.css';
import '../components/base/base.css';
import { useAuthErrorHandle } from '../lib/graphql/authError';
import { LOGIN_PAGE_URL } from './login';

const useLoginPageRedirect = () => {
  // const router = useRouter();
  useAuthErrorHandle(() => {
    // router.push(LOGIN_PAGE_URL); // 本当はSPAで遷移させたいが、Apolloのエラーモーダルが鬱陶しいのでかいけつまでページ遷移で解決
    window.location.href = LOGIN_PAGE_URL;
  });
};

export default ({ Component, pageProps }: AppProps) => {
  const apolloClient = useApollo(pageProps);
  useLoginPageRedirect();

  return (
    <ApolloProvider client={apolloClient}>
      <Component {...pageProps} />
    </ApolloProvider>
  );
};
