import React, { useState } from 'react';
import { SubmitHandler } from 'react-hook-form';
import { usePathname, useSearchParams } from 'next/navigation';
import DishForm from './DishForm';
import useDish, { AddDishFunc } from '../../../features/dish/useDish';
import type { AddDishInput } from '../../../features/dish/useDish';
import {
  CHOOSING_PUT_DISH_SOURCE_TYPE,
  useChoosingPutDishSourceType,
} from './DishForm/useChoosingPutDishSourceType';
import { Dish } from '../../../lib/graphql/generated/graphql';

type Props = {
  onAddingSucceeded?: (doContinuousRegistration: boolean) => void;
  onSchemaError?: any;
  preFilledDish?: Partial<Dish>;
  doContinuousRegistrationDefaultValue?: boolean;
};

export default (props: Props) => {
  const {
    onAddingSucceeded,
    onSchemaError,
    preFilledDish,
    doContinuousRegistrationDefaultValue = false,
  } = props;

  const {
    addDish,
    AddDishSchema,
    addDishWithNewSource,
    AddDishWithNewSourceSchema,
  } = useDish();

  const useChoosingPutDishSourceTypeResult = useChoosingPutDishSourceType(
    CHOOSING_PUT_DISH_SOURCE_TYPE.CHOOSING_USE_EXISTING_DISH_SOURCE,
  );
  const { choosingRegisterNewDishSource, choosingUseExistingDishSource } =
    useChoosingPutDishSourceTypeResult;

  const [doContinuousRegistration, setDoContinuousRegistration] = useState(
    doContinuousRegistrationDefaultValue,
  );
  const toggleDoContinuousRegistration = () => {
    setDoContinuousRegistration(!doContinuousRegistration);
  };

  const {
    addDishFunc,
    addDishSchema,
  }: { addDishFunc: AddDishFunc; addDishSchema: any } = (() => {
    if (choosingRegisterNewDishSource) {
      return {
        addDishFunc: addDishWithNewSource,
        addDishSchema: AddDishWithNewSourceSchema,
      };
    }
    if (choosingUseExistingDishSource) {
      return {
        addDishFunc: addDish,
        addDishSchema: AddDishSchema,
      };
    }
  })();

  const onSubmit: SubmitHandler<AddDishInput> = async (input) => {
    await addDishFunc(input, {
      onCompleted: (_) => {
        if (onAddingSucceeded) onAddingSucceeded(doContinuousRegistration);
      },
    });
  };

  return (
    <DishForm
      formSchema={addDishSchema}
      onSubmit={onSubmit}
      onSchemaError={onSchemaError}
      preFilledDish={preFilledDish as Dish}
      useChoosingPutDishSourceTypeResult={useChoosingPutDishSourceTypeResult}
      doContinuousRegistration={doContinuousRegistration}
      toggleDoContinuousRegistration={toggleDoContinuousRegistration}
    />
  );
};
