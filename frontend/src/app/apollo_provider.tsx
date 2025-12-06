'use client';

import React from 'react';
import { ApolloProvider } from '@apollo/client/react';
// import { useRouter } from 'next/router';
import { useApollo } from '../lib/graphql/buildApolloClient';
import 'bootstrap/dist/css/bootstrap.min.css';
import '../components/base/base.css';
import { useAuthErrorHandle } from '../lib/graphql/authError';
import { LOGIN_PAGE_PATH } from '../app/login/consts';

const useLoginPageRedirect = () => {
  // const router = useRouter();
  useAuthErrorHandle(() => {
    // router.push(LOGIN_PAGE_URL); // 本当はSPAで遷移させたいが、Apolloのエラーモーダルが鬱陶しいのでかいけつまでページ遷移で解決
    window.location.href = LOGIN_PAGE_PATH;
  });
};

type Props = {
  children: React.ReactNode;
};

// TODO: providerをappから出して、どこかにまとめて置く
export default ({ children }: Props) => {
  const apolloClient = useApollo({});
  useLoginPageRedirect();

  return <ApolloProvider client={apolloClient}>{children}</ApolloProvider>;
};
