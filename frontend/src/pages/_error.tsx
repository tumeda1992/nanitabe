import { NextPage, NextPageContext } from 'next';
import Error from 'next/error';
import React from 'react';

interface Props {
  statusCode?: number
}

const ErrorPage: NextPage<Props> = (props: Props) => {
  const { statusCode } = props;
  return statusCode ? (
    <Error statusCode={statusCode} />
  ) : (
    <p>An error occurred on client</p>
  );
};

ErrorPage.getInitialProps = ({ res, err }: NextPageContext) => {
  const statusCode = (() => {
    if (res) return res.statusCode;
    if (err) return err.statusCode || 500;
    return 404;
  })();
  return { statusCode };
};

export default ErrorPage;
