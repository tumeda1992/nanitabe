import React from 'react';
import { usePathname, useSearchParams } from 'next/navigation';
import { useRouter } from 'next/router';
import { AddDish } from '../../components/dish/DishForm';
import { parseIntOrNull } from '../../features/utils/numberUtils';
import { DISHSOURCES_PAGE_URL } from '../../app/dishsources/consts';

export const getServerSideProps = async () => {
  return { props: {} };
};

export default () => {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  if (!router.isReady) return <div>loading...</div>;

  const preFilledDish = (() => {
    const dish = {};
    const mealPosition = parseIntOrNull(searchParams?.get('mealPosition'));
    if (mealPosition) {
      dish['mealPosition'] = mealPosition;
    }

    const dishSourceId = parseIntOrNull(searchParams?.get('dishSourceId'));
    if (dishSourceId) {
      dish['dishSourceRelation'] = { dishSourceId };
    }

    return dish;
  })();

  const doContinuousRegistrationDefaultValue =
    searchParams?.get('doContinuousRegistration') === 'true';

  return (
    <AddDish
      onAddingSucceeded={(doContinuousRegistration) => {
        if (doContinuousRegistration) {
          const params = (() => {
            if (!searchParams) return new URLSearchParams();
            return new URLSearchParams(searchParams);
          })();
          params.set('doContinuousRegistration', 'true');
          window.location.href = `${pathname}?${params}`;
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
