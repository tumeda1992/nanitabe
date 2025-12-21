import { useAddMeal } from './addMealMutation';
import { FetchMealsParams, useFetchMeals } from './fetchMealQuery';
import { useUpdateMeal } from './updateMealMutation';
import { useRemoveMeal } from './removeMealMutation';
import { useSwapMealsBetweenDays } from './swapMealsBetweenDaysMutation';

export type {
  AddMealMutationInput,
  AddMealMutationOutput,
  AddMealFunc,
} from './addMealMutation';
export type {
  UpdateMealWithNewDishAndNewSource,
  UpdateMeal,
  UpdateMealInput,
  UpdateMealOutput,
  UpdateMealFunc,
} from './updateMealMutation';

export type UseMealParams = {
  fetchMealsParams?: FetchMealsParams;
};

export default (params: UseMealParams = {}) => {
  const { fetchMealsParams } = params;

  const {
    addMeal,
    AddMealSchema,
    addMealWithNewDishAndNewSource,
    AddMealWithNewDishAndNewSourceSchema,
    addMealWithNewDish,
    AddMealWithNewDishSchema,
    addMealLoading,
    addMealError,
  } = useAddMeal();

  const {
    updateMeal,
    UpdateMealSchema,
    updateMealWithNewDish,
    UpdateMealWithNewDishSchema,
    updateMealWithNewDishAndNewSource,
    UpdateMealWithNewDishAndNewSourceSchema,
    updateMealLoading,
    updateMealError,
  } = useUpdateMeal();

  const { removeMeal, removeMealLoading, removeMealError } = useRemoveMeal();

  const {
    mealsForCalender,
    refetchMealsForCalender,
    fetchMealsLoading,
    fetchMealsError,
  } = useFetchMeals(fetchMealsParams || {});

  const {
    swapMealsBetweenDays,
    swapMealsBetweenDaysLoading,
    swapMealsBetweenDaysError,
  } = useSwapMealsBetweenDays();

  return {
    mealsForCalender,
    fetchMealsLoading,
    fetchMealsError,
    refetchMealsForCalender,

    addMeal,
    AddMealSchema,
    addMealWithNewDish,
    AddMealWithNewDishSchema,
    addMealWithNewDishAndNewSource,
    AddMealWithNewDishAndNewSourceSchema,
    addMealLoading,
    addMealError,

    updateMeal,
    UpdateMealSchema,
    updateMealWithNewDish,
    UpdateMealWithNewDishSchema,
    updateMealWithNewDishAndNewSource,
    UpdateMealWithNewDishAndNewSourceSchema,
    updateMealLoading,
    updateMealError,

    removeMeal,
    removeMealLoading,
    removeMealError,

    swapMealsBetweenDays,
    swapMealsBetweenDaysLoading,
    swapMealsBetweenDaysError,
  };
};
