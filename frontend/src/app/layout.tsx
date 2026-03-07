import './globals.css';
import React from 'react';
import type { Metadata } from 'next';
import ApolloProvider from './apollo_provider';
import { LogicalHistoryProvider } from './logical-history';
// TODO: bootstrapのCSSを適切に読み込む
// import 'bootstrap/dist/css/bootstrap.min.css';

export const metadata: Metadata = {
  title: 'なにたべ',
  icons: {
    icon: '/favicon.ico',
    apple: '/webclip.jpeg',
  },
};

type Props = {
  children: React.ReactNode;
};

export default ({ children }: Props) => (
  <html lang="ja">
    <head>
      <link
        href="https://use.fontawesome.com/releases/v6.3.0/css/all.css"
        rel="stylesheet"
      />
    </head>
    <body>
      <ApolloProvider>
        <LogicalHistoryProvider>{children}</LogicalHistoryProvider>
      </ApolloProvider>
    </body>
  </html>
);
