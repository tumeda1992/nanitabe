import React from 'react';
import Login from '../components/auth/Login';

export const LOGIN_PAGE_URL = '/login';

export const getServerSideProps = async () => {
  return { props: {} };
};

export default (props) => {
  return <Login />;
};
