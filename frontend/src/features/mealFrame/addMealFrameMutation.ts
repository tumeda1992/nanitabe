import { gql } from '@apollo/client';
import * as z from 'zod';
import {
  AddMealFrameMutation,
  useAddMealFrameMutation,
} from '../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../utils/mutationUtils';
import { newMealFrameSchema } from './schema';

export const ADD_MEAL_FRAME = gql`
  mutation addMealFrame($mealFrame: MealFrameForCreate!) {
    addMealFrame(input: { mealFrame: $mealFrame }) {
      mealFrameId
    }
  }
`;

const AddMealFrameSchema = z.object({
  mealFrame: newMealFrameSchema,
});
export type AddMealFrameInput = z.infer<typeof AddMealFrameSchema>;

export type AddMealFrameFunc = (
  input: AddMealFrameInput,
  mutationCallbacks: MutationCallbacks<AddMealFrameMutation>,
) => void;

export const useAddMealFrame = () => {
  const [addMealFrame, addMealFrameLoading, addMealFrameError] =
    buildMutationExecutor<AddMealFrameInput, AddMealFrameMutation>(
      useAddMealFrameMutation,
    );

  return {
    addMealFrame,
    AddMealFrameSchema,
    addMealFrameLoading,
    addMealFrameError,
  };
};
