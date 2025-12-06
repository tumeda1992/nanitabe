'use client';

import React from 'react';
import { EditSource } from '../../../../components/dish/Source/SourceForm';
import useDishSource from '../../../../features/dish/source/useDishSource';

import { DISHSOURCES_PAGE_PATH } from '../../consts';

type Props = {
  dishSourceIdString: string;
};

export default (props: Props) => {
  const { dishSourceIdString } = props;
  const { dishSource } = useDishSource({
    fetchDishSourcesParams: {
      fetchDishSourceParams: {
        requireFetchedData: true,
        condition: { id: Number(dishSourceIdString) },
      },
    },
  });

  return (
    <>
      {dishSource && (
        <EditSource
          dishSource={dishSource}
          onEditSucceeded={() => {
            window.location.href = DISHSOURCES_PAGE_PATH;
          }}
        />
      )}
    </>
  );
};
