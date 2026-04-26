import { gql } from '@apollo/client';
import * as z from 'zod';
import {
  DeleteMealFrameMutation,
  useDeleteMealFrameMutation,
} from '../../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../../utils/mutationUtils';
import { mealFrameIdSchema } from './schema';

export const DELETE_MEAL_FRAME = gql`
  mutation deleteMealFrame($id: Int!) {
    deleteMealFrame(input: { id: $id }) {
      mealFrameId
    }
  }
`;

const DeleteMealFrameSchema = z.object({
  id: mealFrameIdSchema,
});
export type DeleteMealFrameInput = z.infer<typeof DeleteMealFrameSchema>;

export type DeleteMealFrameFunc = (
  input: DeleteMealFrameInput,
  mutationCallbacks: MutationCallbacks<DeleteMealFrameMutation>,
) => void;

export const useDeleteMealFrame = () => {
  const [deleteMealFrame, deleteMealFrameLoading, deleteMealFrameError] =
    buildMutationExecutor<DeleteMealFrameInput, DeleteMealFrameMutation>(
      useDeleteMealFrameMutation,
    );

  return {
    deleteMealFrame,
    DeleteMealFrameSchema,
    deleteMealFrameLoading,
    deleteMealFrameError,
  };
};
