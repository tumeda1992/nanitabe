'use client';

import React from 'react';
import { EditDish } from '../../../../components/dish/DishForm';
import useDish from '../../../../features/dish/useDish';
import { DISHSOURCES_PAGE_PATH } from '../../../../app/dishsources/consts';

type Props = {
  dishIdString: string;
};

export default (props: Props) => {
  const { dishIdString } = props;
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
            window.location.href = DISHSOURCES_PAGE_PATH;
          }}
        />
      )}
    </>
  );
};
