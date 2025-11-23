import React from 'react';
import { useRouter } from 'next/router';
import { EditDish } from '../../../components/dish/DishForm';
import useDish from '../../../features/dish/useDish';

import { DISHSOURCES_PAGE_URL } from '../../../app/dishsources/consts';

export const getServerSideProps = async () => {
  return { props: {} };
};

export default () => {
  const router = useRouter();
  const { dishId: dishIdString } = router.query;

  const { dish } = useDish({
    fetchDishesParams: {
      fetchDishParams: {
        requireFetchedData: true,
        condition: { id: Number(dishIdString) },
      },
    },
  });

  return (
    <>
      {dish && (
        <EditDish
          dish={dish}
          onEditSucceeded={() => {
            window.location.href = DISHSOURCES_PAGE_URL;
          }}
        />
      )}
    </>
  );
};
