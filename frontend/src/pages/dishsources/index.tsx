import React from 'react';
import DishSources from '../../components/dish/Source';

export const DISHSOURCES_PAGE_URL = '/dishsources';

export const getServerSideProps = async () => {
  return { props: {} };
};

export default () => {
  return <DishSources />;
};
