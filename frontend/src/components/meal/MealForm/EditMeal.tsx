import React from 'react';
import { SubmitHandler } from 'react-hook-form';
import { parseISO } from 'date-fns';
import MealForm from './MealForm';
import { MealForCalender } from '../../../lib/graphql/generated/graphql';
import useMeal, {
  UpdateMealFunc,
  UpdateMealInput,
} from '../../../features/meal/useMeal';
import {
  CHOOSING_PUT_DISH_SOURCE_TYPE,
  useChoosingPutDishSourceType,
} from '../../dish/DishForm/DishForm/useChoosingPutDishSourceType';
import {
  CHOOSING_DISH_TYPE,
  useChoosingDishType,
} from './MealForm/useChoosingDishType';

type Props = {
  meal: MealForCalender;
  onEditSucceeded?: () => void;
  onSchemaError?: any;
};

export default (props: Props) => {
  const { meal, onEditSucceeded, onSchemaError } = props;

  const {
    updateMeal,
    UpdateMealSchema,

    updateMealWithNewDish,
    UpdateMealWithNewDishSchema,

    updateMealWithNewDishAndNewSource,
    UpdateMealWithNewDishAndNewSourceSchema,
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
    updateMealFunc,
    updateMealSchema,
  }: { updateMealFunc: UpdateMealFunc; updateMealSchema: any } = (() => {
    if (choosingUseExistingDish) {
      return {
        updateMealFunc: updateMeal,
        updateMealSchema: UpdateMealSchema,
      };
    }

    // if (choosingRegisterNewDish) の分岐
    if (choosingUseExistingDishSource) {
      return {
        updateMealFunc: updateMealWithNewDish,
        updateMealSchema: UpdateMealWithNewDishSchema,
      };
    }
    if (choosingRegisterNewDishSource) {
      return {
        updateMealFunc: updateMealWithNewDishAndNewSource,
        updateMealSchema: UpdateMealWithNewDishAndNewSourceSchema,
      };
    }
    return {
      updateMealFunc: null,
      updateMealSchema: null,
    };
  })();

  const onSubmit: SubmitHandler<UpdateMealInput> = async (input) => {
    await updateMealFunc(input, {
      onCompleted: (data) => {
        if (onEditSucceeded) onEditSucceeded();
      },
    });
  };

  return (
    <MealForm
      formSchema={updateMealSchema}
      onSubmit={onSubmit}
      defaultDate={parseISO(meal.date)}
      registeredMealId={meal.id}
      registeredMealType={meal.mealType}
      registeredDishId={meal.dish.id}
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
