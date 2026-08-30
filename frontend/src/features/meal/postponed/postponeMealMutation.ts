import { gql } from '@apollo/client';
import {
  PostponeMealMutation,
  usePostponeMealMutation,
} from '../../../lib/graphql/generated/graphql';
import { buildMutationExecutor } from '../../utils/mutationUtils';

export const POSTPONE_MEAL = gql`
  mutation postponeMeal($mealId: Int!) {
    postponeMeal(input: { mealId: $mealId }) {
      postponedMealId
    }
  }
`;

export const usePostponeMeal = () => {
  const [postponeMeal, postponeMealLoading, postponeMealError] =
    buildMutationExecutor<{ mealId: number }, PostponeMealMutation>(
      usePostponeMealMutation,
    );

  return {
    postponeMeal,

    postponeMealLoading,
    postponeMealError,
  };
};
