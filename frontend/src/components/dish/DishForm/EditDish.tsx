import React from 'react';
import { SubmitHandler } from 'react-hook-form';
import DishForm from './DishForm';
import { Dish } from '../../../lib/graphql/generated/graphql';
import useDish, {
  UpdateDishInput,
  UpdateDishFunc,
} from '../../../features/dish/useDish';
import {
  CHOOSING_PUT_DISH_SOURCE_TYPE,
  useChoosingPutDishSourceType,
} from './DishForm/useChoosingPutDishSourceType';

type Props = {
  dish: Dish;
  onEditSucceeded?: () => void;
  onSchemaError?: any;
};

export default (props: Props) => {
  const { dish, onEditSucceeded, onSchemaError } = props;

  const {
    updateDish,
    UpdateDishSchema,
    updateDishWithNewSource,
    UpdateDishWithNewSourceSchema,
  } = useDish();

  const useChoosingPutDishSourceTypeResult = useChoosingPutDishSourceType(
    CHOOSING_PUT_DISH_SOURCE_TYPE.CHOOSING_USE_EXISTING_DISH_SOURCE,
  );

  const { choosingRegisterNewDishSource, choosingUseExistingDishSource } =
    useChoosingPutDishSourceTypeResult;

  const {
    updateDishFunc,
    updateDishSchema,
  }: { updateDishFunc: UpdateDishFunc; updateDishSchema: any } = (() => {
    if (choosingUseExistingDishSource) {
      return {
        updateDishFunc: updateDish,
        updateDishSchema: UpdateDishSchema,
      };
    }
    if (choosingRegisterNewDishSource) {
      return {
        updateDishFunc: updateDishWithNewSource,
        updateDishSchema: UpdateDishWithNewSourceSchema,
      };
    }
  })();

  const onSubmit: SubmitHandler<UpdateDishInput> = async (input) => {
    await updateDishFunc(input, {
      onCompleted: (_) => {
        if (onEditSucceeded) onEditSucceeded();
      },
    });
  };

  return (
    <DishForm
      formSchema={updateDishSchema}
      onSubmit={onSubmit}
      onSchemaError={onSchemaError}
      preFilledDish={dish}
      useChoosingPutDishSourceTypeResult={useChoosingPutDishSourceTypeResult}
    />
  );
};
