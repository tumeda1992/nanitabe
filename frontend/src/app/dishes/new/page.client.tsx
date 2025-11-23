'use client';

import React from 'react';
import { usePathname } from 'next/navigation';
import { AddDish } from '../../../components/dish/DishForm';
import { DISHSOURCES_PAGE_URL } from '../../dishsources/consts';
import { SearchParams } from '../../next-types';

type Props = {
  preFilledDish: any;
  doContinuousRegistrationDefaultValue: boolean;
  searchParams: SearchParams;
};

export default (props: Props) => {
  const { preFilledDish, doContinuousRegistrationDefaultValue, searchParams } =
    props;
  const pathname = usePathname();

  return (
    <AddDish
      onAddingSucceeded={(doContinuousRegistration) => {
        if (doContinuousRegistration) {
          const params = new URLSearchParams(searchParams.toString());
          params.set('doContinuousRegistration', 'true');
          window.location.href = `${pathname}?${params.toString()}`;
        } else {
          window.location.href = DISHSOURCES_PAGE_URL;
        }
      }}
      preFilledDish={preFilledDish}
      doContinuousRegistrationDefaultValue={
        doContinuousRegistrationDefaultValue
      }
    />
  );
};
