'use client';

import React from 'react';
import { AddSource } from '../../../components/dish/Source/SourceForm';

import { DISHSOURCES_PAGE_PATH } from '../../dishsources/consts';

export default () => {
  return (
    <AddSource
      onAddSucceeded={() => {
        window.location.href = DISHSOURCES_PAGE_PATH;
      }}
    />
  );
};
