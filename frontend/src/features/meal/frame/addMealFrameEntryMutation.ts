import { gql } from '@apollo/client';
import * as z from 'zod';
import {
  AddMealFrameEntryMutation,
  useAddMealFrameEntryMutation,
} from '../../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../../utils/mutationUtils';

export const ADD_MEAL_FRAME_ENTRY = gql`
  mutation addMealFrameEntry($mealFrameEntry: MealFrameEntryForCreate!) {
    addMealFrameEntry(input: { mealFrameEntry: $mealFrameEntry }) {
      mealFrameEntryId
    }
  }
`;

const AddMealFrameEntrySchema = z.object({
  mealFrameEntry: z.object({
    mealFrameId: z.number({ required_error: '枠を選択してください。' }),
    date: z.string({ required_error: '日付は必須です。' }),
    mealType: z.number({ required_error: '食事タイプを選択してください。' }),
  }),
});
export type AddMealFrameEntryInput = z.infer<typeof AddMealFrameEntrySchema>;

export type AddMealFrameEntryFunc = (
  input: AddMealFrameEntryInput,
  mutationCallbacks: MutationCallbacks<AddMealFrameEntryMutation>,
) => void;

export const useAddMealFrameEntry = () => {
  const [addMealFrameEntry, addMealFrameEntryLoading, addMealFrameEntryError] =
    buildMutationExecutor<AddMealFrameEntryInput, AddMealFrameEntryMutation>(
      useAddMealFrameEntryMutation,
    );

  return {
    addMealFrameEntry,
    AddMealFrameEntrySchema,
    addMealFrameEntryLoading,
    addMealFrameEntryError,
  };
};
