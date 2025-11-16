import React from 'react';
import { AddSource } from '../../components/dish/Source/SourceForm';
import { DISHSOURCES_PAGE_URL } from './index';

export const DISHSOURCE_NEW_PAGE_URL = '/dishsources/new';

export const getServerSideProps = async () => {
  return { props: {} };
};

export default () => {
  return (
    <AddSource
      onAddSucceeded={() => {
        window.location.href = DISHSOURCES_PAGE_URL;
      }}
    />
  );
};
