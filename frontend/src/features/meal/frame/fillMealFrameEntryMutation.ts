import { gql } from '@apollo/client';
import * as z from 'zod';
import {
  FillMealFrameEntryMutation,
  useFillMealFrameEntryMutation,
} from '../../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../../utils/mutationUtils';

export const FILL_MEAL_FRAME_ENTRY = gql`
  mutation fillMealFrameEntry($frameEntryId: Int!, $mealId: Int!) {
    fillMealFrameEntry(input: { frameEntryId: $frameEntryId, mealId: $mealId }) {
      frameEntryId
    }
  }
`;

const FillMealFrameEntrySchema = z.object({
  frameEntryId: z.number().int().positive(),
  mealId: z.number().int().positive(),
});
export type FillMealFrameEntryInput = z.infer<typeof FillMealFrameEntrySchema>;

export type FillMealFrameEntryFunc = (
  input: FillMealFrameEntryInput,
  mutationCallbacks: MutationCallbacks<FillMealFrameEntryMutation>,
) => void;

export const useFillMealFrameEntry = () => {
  const [
    fillMealFrameEntry,
    fillMealFrameEntryLoading,
    fillMealFrameEntryError,
  ] = buildMutationExecutor<FillMealFrameEntryInput, FillMealFrameEntryMutation>(
    useFillMealFrameEntryMutation,
  );

  return {
    fillMealFrameEntry,
    FillMealFrameEntrySchema,
    fillMealFrameEntryLoading,
    fillMealFrameEntryError,
  };
};
