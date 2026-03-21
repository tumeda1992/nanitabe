import { gql } from '@apollo/client';
import * as z from 'zod';
import {
  RemoveMealFrameEntryMutation,
  useRemoveMealFrameEntryMutation,
} from '../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../utils/mutationUtils';

export const REMOVE_MEAL_FRAME_ENTRY = gql`
  mutation removeMealFrameEntry($id: Int!) {
    removeMealFrameEntry(input: { id: $id }) {
      mealFrameEntryId
    }
  }
`;

const RemoveMealFrameEntrySchema = z.object({
  id: z.number().int().positive(),
});
export type RemoveMealFrameEntryInput = z.infer<
  typeof RemoveMealFrameEntrySchema
>;

export type RemoveMealFrameEntryFunc = (
  input: RemoveMealFrameEntryInput,
  mutationCallbacks: MutationCallbacks<RemoveMealFrameEntryMutation>,
) => void;

export const useRemoveMealFrameEntry = () => {
  const [
    removeMealFrameEntry,
    removeMealFrameEntryLoading,
    removeMealFrameEntryError,
  ] = buildMutationExecutor<
    RemoveMealFrameEntryInput,
    RemoveMealFrameEntryMutation
  >(useRemoveMealFrameEntryMutation);

  return {
    removeMealFrameEntry,
    RemoveMealFrameEntrySchema,
    removeMealFrameEntryLoading,
    removeMealFrameEntryError,
  };
};
