import { gql } from '@apollo/client';
import {
  SchedulePostponedMealMutation,
  useSchedulePostponedMealMutation,
} from '../../../lib/graphql/generated/graphql';
import { buildMutationExecutor } from '../../utils/mutationUtils';

export const SCHEDULE_POSTPONED_MEAL = gql`
  mutation schedulePostponedMeal($postponedMealId: Int!, $date: ISO8601Date!) {
    schedulePostponedMeal(
      input: { postponedMealId: $postponedMealId, date: $date }
    ) {
      mealId
    }
  }
`;

export const useSchedulePostponedMeal = () => {
  const [
    schedulePostponedMeal,
    schedulePostponedMealLoading,
    schedulePostponedMealError,
  ] = buildMutationExecutor<
    { postponedMealId: number; date: Date },
    SchedulePostponedMealMutation
  >(useSchedulePostponedMealMutation);

  return {
    schedulePostponedMeal,

    schedulePostponedMealLoading,
    schedulePostponedMealError,
  };
};
