import React from 'react';
import { SubmitHandler } from 'react-hook-form';
import useMeal, { AddMealFunc } from '../../../features/meal/useMeal';
import type { AddMealMutationInput } from '../../../features/meal/useMeal';
import MealForm from './MealForm';
import {
  CHOOSING_PUT_DISH_SOURCE_TYPE,
  useChoosingPutDishSourceType,
} from '../../dish/DishForm/DishForm/useChoosingPutDishSourceType';
import {
  CHOOSING_DISH_TYPE,
  useChoosingDishType,
} from './MealForm/useChoosingDishType';

type Props = {
  defaultDate?: Date;
  onAddSucceeded?: () => void;
  onSchemaError?: any;
};

export default (props: Props) => {
  const { defaultDate: defaultDateArg, onAddSucceeded, onSchemaError } = props;
  const defaultDate: Date = defaultDateArg || new Date();

  const {
    addMeal,
    AddMealSchema,

    addMealWithNewDish,
    AddMealWithNewDishSchema,

    addMealWithNewDishAndNewSource,
    AddMealWithNewDishAndNewSourceSchema,
  } = useMeal();

  const {
    choosingDishType,
    setChoosingDishType,
    choosingRegisterNewDish,
    choosingUseExistingDish,
  } = useChoosingDishType(CHOOSING_DISH_TYPE.CHOOSING_USE_EXISTING_DISH);

  const useChoosingPutDishSourceTypeResult = useChoosingPutDishSourceType(
    CHOOSING_PUT_DISH_SOURCE_TYPE.CHOOSING_USE_EXISTING_DISH_SOURCE,
  );
  const { choosingRegisterNewDishSource, choosingUseExistingDishSource } =
    useChoosingPutDishSourceTypeResult;

  const {
    addMealFunc,
    addMealSchema,
  }: {
    addMealFunc: AddMealFunc;
    addMealSchema: any;
  } = (() => {
    if (choosingUseExistingDish) {
      return {
        addMealFunc: addMeal,
        addMealSchema: AddMealSchema,
      };
    }
    // if (choosingRegisterNewDish) の分岐
    if (choosingUseExistingDishSource) {
      return {
        addMealFunc: addMealWithNewDish,
        addMealSchema: AddMealWithNewDishSchema,
      };
    }
    if (choosingRegisterNewDishSource) {
      return {
        addMealFunc: addMealWithNewDishAndNewSource,
        addMealSchema: AddMealWithNewDishAndNewSourceSchema,
      };
    }
    return {
      addMealFunc: null,
      addMealSchema: null,
    };
  })();

  const onSubmit: SubmitHandler<AddMealMutationInput> = async (input) => {
    await addMealFunc(input, {
      onCompleted: (_) => {
        if (onAddSucceeded) onAddSucceeded();
        // コンポーネント内にあるから触れなくなっちゃったけど、必要になったらフォーム内のものを動かせるようにする
        // reset();
      },
      onError: (error) => {},
    });
  };

  return (
    <MealForm
      formSchema={addMealSchema}
      onSubmit={onSubmit}
      defaultDate={defaultDate}
      useChoosingDishTypeResult={{
        choosingDishType,
        setChoosingDishType,
        choosingRegisterNewDish,
        choosingUseExistingDish,
      }}
      useChoosingPutDishSourceTypeResult={useChoosingPutDishSourceTypeResult}
      onSchemaError={onSchemaError}
    />
  );
};
