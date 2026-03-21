import { gql } from '@apollo/client';
import * as z from 'zod';
import {
  UpdateMealFrameMutation,
  useUpdateMealFrameMutation,
} from '../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../utils/mutationUtils';
import { mealFrameIdSchema, mealFrameNameSchema } from './schema';

export const UPDATE_MEAL_FRAME = gql`
  mutation updateMealFrame($mealFrame: MealFrameForUpdate!) {
    updateMealFrame(input: { mealFrame: $mealFrame }) {
      mealFrameId
    }
  }
`;

const UpdateMealFrameSchema = z.object({
  mealFrame: z.object({
    id: mealFrameIdSchema,
    name: mealFrameNameSchema,
  }),
});
export type UpdateMealFrameInput = z.infer<typeof UpdateMealFrameSchema>;

export type UpdateMealFrameFunc = (
  input: UpdateMealFrameInput,
  mutationCallbacks: MutationCallbacks<UpdateMealFrameMutation>,
) => void;

export const useUpdateMealFrame = () => {
  const [updateMealFrame, updateMealFrameLoading, updateMealFrameError] =
    buildMutationExecutor<UpdateMealFrameInput, UpdateMealFrameMutation>(
      useUpdateMealFrameMutation,
    );

  return {
    updateMealFrame,
    UpdateMealFrameSchema,
    updateMealFrameLoading,
    updateMealFrameError,
  };
};
