import { gql } from '@apollo/client';
import type * as z from 'zod';
import {
  AddMealFramePatternMutation,
  useAddMealFramePatternMutation,
} from '../../../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../../../utils/mutationUtils';
import { MEAL_FRAME_PATTERNS } from './mealFramePatternsQuery';
import { addMealFramePatternSchema } from './schema';

export const ADD_MEAL_FRAME_PATTERN = gql`
  mutation addMealFramePattern($mealFramePattern: MealFramePatternForCreate!) {
    addMealFramePattern(input: { mealFramePattern: $mealFramePattern }) {
      mealFramePatternId
    }
  }
`;

export type AddMealFramePatternInput = z.infer<
  typeof addMealFramePatternSchema
>;

export type AddMealFramePatternFunc = (
  input: AddMealFramePatternInput,
  mutationCallbacks: MutationCallbacks<AddMealFramePatternMutation>,
) => void;

export const useAddMealFramePattern = () => {
  const [
    addMealFramePattern,
    addMealFramePatternLoading,
    addMealFramePatternError,
  ] = buildMutationExecutor<
    AddMealFramePatternInput,
    AddMealFramePatternMutation
  >(useAddMealFramePatternMutation, {
    refetchQueries: [{ query: MEAL_FRAME_PATTERNS }],
  });

  return {
    addMealFramePattern,
    addMealFramePatternSchema: addMealFramePatternSchema,
    addMealFramePatternLoading,
    addMealFramePatternError,
  };
};
