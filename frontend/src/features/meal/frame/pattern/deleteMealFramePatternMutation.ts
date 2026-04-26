import { gql } from '@apollo/client';
import * as z from 'zod';
import {
  DeleteMealFramePatternMutation,
  useDeleteMealFramePatternMutation,
} from '../../../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../../../utils/mutationUtils';

export const DELETE_MEAL_FRAME_PATTERN = gql`
  mutation deleteMealFramePattern($id: Int!) {
    deleteMealFramePattern(input: { id: $id }) {
      mealFramePatternId
    }
  }
`;

const deleteMealFramePatternSchema = z.object({
  id: z.number(),
});

export type DeleteMealFramePatternInput = z.infer<typeof deleteMealFramePatternSchema>;

export type DeleteMealFramePatternFunc = (
  input: DeleteMealFramePatternInput,
  mutationCallbacks: MutationCallbacks<DeleteMealFramePatternMutation>,
) => void;

export const useDeleteMealFramePattern = () => {
  const [deleteMealFramePattern, deleteMealFramePatternLoading, deleteMealFramePatternError] =
    buildMutationExecutor<DeleteMealFramePatternInput, DeleteMealFramePatternMutation>(
      useDeleteMealFramePatternMutation,
    );

  return {
    deleteMealFramePattern,
    deleteMealFramePatternLoading,
    deleteMealFramePatternError,
  };
};
