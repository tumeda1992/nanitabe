import { gql } from '@apollo/client';
import type * as z from 'zod';
import {
  UpdateMealFramePatternMutation,
  useUpdateMealFramePatternMutation,
} from '../../../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../../../utils/mutationUtils';
import { MEAL_FRAME_PATTERNS } from './mealFramePatternsQuery';
import { updateMealFramePatternSchema } from './schema';

export const UPDATE_MEAL_FRAME_PATTERN = gql`
  mutation updateMealFramePattern(
    $mealFramePattern: MealFramePatternForUpdate!
  ) {
    updateMealFramePattern(input: { mealFramePattern: $mealFramePattern }) {
      mealFramePatternId
    }
  }
`;

export type UpdateMealFramePatternInput = z.infer<
  typeof updateMealFramePatternSchema
>;

export type UpdateMealFramePatternFunc = (
  input: UpdateMealFramePatternInput,
  mutationCallbacks: MutationCallbacks<UpdateMealFramePatternMutation>,
) => void;

export const useUpdateMealFramePattern = () => {
  const [
    updateMealFramePattern,
    updateMealFramePatternLoading,
    updateMealFramePatternError,
  ] = buildMutationExecutor<
    UpdateMealFramePatternInput,
    UpdateMealFramePatternMutation
  >(useUpdateMealFramePatternMutation, {
    refetchQueries: [{ query: MEAL_FRAME_PATTERNS }],
  });

  return {
    updateMealFramePattern,
    updateMealFramePatternLoading,
    updateMealFramePatternError,
  };
};
