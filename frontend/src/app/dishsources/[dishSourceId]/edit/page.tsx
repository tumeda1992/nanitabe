import React from 'react';
import { EditSource } from '../../../../components/dish/Source/SourceForm';
import useDishSource from '../../../../features/dish/source/useDishSource';

import { DISHSOURCES_PAGE_URL } from '../../consts';

export default async ({
  searchParams,
}: {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) => {
  const { dishSourceId: dishSourceIdString } = await searchParams;

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
            window.location.href = DISHSOURCES_PAGE_URL;
          }}
        />
      )}
    </>
  );
};
