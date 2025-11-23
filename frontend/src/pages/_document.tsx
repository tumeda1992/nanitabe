/* eslint-disable object-curly-newline */
import { Html, Head, Main, NextScript } from 'next/document';
import React from 'react';

export default () => {
  return (
    <Html>
      <Head>
        <link
          href="https://use.fontawesome.com/releases/v6.3.0/css/all.css"
          rel="stylesheet"
        />
        <link rel="icon" type="image/png" sizes="32x32" href="/favicon.ico" />
        <link rel="apple-touch-icon" sizes="180x180" href="/webclip.jpeg" />
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
};
