import { usePostponeMeal } from './postponeMealMutation';
import { useSchedulePostponedMeal } from './schedulePostponedMealMutation';
import { useFetchPostponedMeals } from './postponedMealsQuery';

type UsePostponedMealParams = {
  requireFetchedData?: boolean;
};

export default (params: UsePostponedMealParams = {}) => {
  const { requireFetchedData = true } = params;

  const { postponeMeal, postponeMealLoading, postponeMealError } =
    usePostponeMeal();

  const {
    schedulePostponedMeal,
    schedulePostponedMealLoading,
    schedulePostponedMealError,
  } = useSchedulePostponedMeal();

  const {
    postponedMeals,
    fetchPostponedMealsLoading,
    fetchPostponedMealsError,
    refetchPostponedMeals,
  } = useFetchPostponedMeals(requireFetchedData);

  return {
    postponeMeal,
    postponeMealLoading,
    postponeMealError,

    schedulePostponedMeal,
    schedulePostponedMealLoading,
    schedulePostponedMealError,

    postponedMeals,
    fetchPostponedMealsLoading,
    fetchPostponedMealsError,
    refetchPostponedMeals,
  };
};
