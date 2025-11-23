import { FetchDishesParams, useFetchDishes } from './fetchDishQuery';
import { useAddDish } from './addDishMutation';
import { useUpdateDish } from './updateDishMutation';
import { useRemoveDish } from './removeDishMutation';

export type {
  AddDishInput,
  AddDishOutput,
  AddDishFunc,
} from './addDishMutation';
export type {
  UpdateDishInput,
  UpdateDishOutput,
  UpdateDishFunc,
} from './updateDishMutation';

export type UseDishParams = {
  fetchDishesParams?: FetchDishesParams;
};

export default (params: UseDishParams = {}) => {
  const { fetchDishesParams } = params;

  const {
    existingDishesForRegisteringWithMeal,
    prefetchedExistingDishesForRegisteringWithMeal,
    dish,
    dishesPerSource,
    fetchLoading,
    fetchError,
    refetchExistingDishesForRegisteringWithMeal,
    refetchDish,
    refetchDishesPerSource,
  } = useFetchDishes(fetchDishesParams || {});

  const {
    addDish,
    AddDishSchema,
    addDishWithNewSource,
    AddDishWithNewSourceSchema,
    addDishLoading,
    addDishError,
  } = useAddDish();
  const {
    updateDish,
    UpdateDishSchema,
    updateDishWithNewSource,
    UpdateDishWithNewSourceSchema,
    evaluateDish,
    updateDishLoading,
    updateDishError,
  } = useUpdateDish();
  const { removeDish, removeDishLoading, removeDishError } = useRemoveDish();

  return {
    existingDishesForRegisteringWithMeal,
    prefetchedExistingDishesForRegisteringWithMeal,
    dish,
    dishesPerSource,
    fetchLoading,
    fetchError,
    refetchExistingDishesForRegisteringWithMeal,
    refetchDish,
    refetchDishesPerSource,

    addDish,
    AddDishSchema,
    addDishWithNewSource,
    AddDishWithNewSourceSchema,
    addDishLoading,
    addDishError,

    updateDish,
    UpdateDishSchema,
    updateDishWithNewSource,
    UpdateDishWithNewSourceSchema,
    evaluateDish,
    updateDishLoading,
    updateDishError,

    removeDish,
    removeDishLoading,
    removeDishError,
  };
};
