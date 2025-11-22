import React from 'react';
import Signup from '../components/auth/Signup';

export const getServerSideProps = async () => {
  return { props: {} };
};

export default (props) => {
  return <Signup />;
};
