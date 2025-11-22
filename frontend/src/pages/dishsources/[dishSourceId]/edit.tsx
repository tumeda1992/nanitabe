import React from 'react';
import { useRouter } from 'next/router';
import { EditSource } from '../../../components/dish/Source/SourceForm';
import useDishSource from '../../../features/dish/source/useDishSource';
import { DISHSOURCES_PAGE_URL } from '../index';

export const getServerSideProps = async () => {
  return { props: {} };
};

export default () => {
  const router = useRouter();
  const { dishSourceId: dishSourceIdString } = router.query;

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
