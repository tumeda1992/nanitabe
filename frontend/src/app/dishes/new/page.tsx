import React from 'react';
import { parseIntOrNull } from '../../../features/utils/numberUtils';
import { NextPagePropsWithSearchParams } from '../../next-types';
import ClientPage from './page.client';

export default async ({ searchParams }: NextPagePropsWithSearchParams) => {
  const {
    mealPosition: mealPositionFromParams,
    dishSourceId: dishSourceIdFromParams,
    doContinuousRegistration: doContinuousRegistrationFromParams,
  } = await searchParams;

  const preFilledDish = (() => {
    const dish = {};
    const mealPosition = parseIntOrNull(mealPositionFromParams);
    if (mealPosition) {
      dish['mealPosition'] = mealPosition;
    }

    const dishSourceId = parseIntOrNull(dishSourceIdFromParams);
    if (dishSourceId) {
      dish['dishSourceRelation'] = { dishSourceId };
    }

    return dish;
  })();

  const doContinuousRegistrationDefaultValue =
    doContinuousRegistrationFromParams === 'true';

  return (
    <ClientPage
      preFilledDish={preFilledDish}
      doContinuousRegistrationDefaultValue={
        doContinuousRegistrationDefaultValue
      }
      searchParams={searchParams}
    />
  );
};
