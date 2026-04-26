import { gql } from '@apollo/client';
import * as z from 'zod';
import {
  UnassignMealFromFrameEntryMutation,
  useUnassignMealFromFrameEntryMutation,
} from '../../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../../utils/mutationUtils';

export const UNASSIGN_MEAL_FROM_FRAME_ENTRY = gql`
  mutation unassignMealFromFrameEntry($frameEntryId: Int!) {
    unassignMealFromFrameEntry(input: { frameEntryId: $frameEntryId }) {
      frameEntryId
    }
  }
`;

const UnassignMealFromFrameEntrySchema = z.object({
  frameEntryId: z.number().int().positive(),
});
export type UnassignMealFromFrameEntryInput = z.infer<
  typeof UnassignMealFromFrameEntrySchema
>;

export type UnassignMealFromFrameEntryFunc = (
  input: UnassignMealFromFrameEntryInput,
  mutationCallbacks: MutationCallbacks<UnassignMealFromFrameEntryMutation>,
) => void;

export const useUnassignMealFromFrameEntry = () => {
  const [
    unassignMealFromFrameEntry,
    unassignMealFromFrameEntryLoading,
    unassignMealFromFrameEntryError,
  ] = buildMutationExecutor<
    UnassignMealFromFrameEntryInput,
    UnassignMealFromFrameEntryMutation
  >(useUnassignMealFromFrameEntryMutation);

  return {
    unassignMealFromFrameEntry,
    UnassignMealFromFrameEntrySchema,
    unassignMealFromFrameEntryLoading,
    unassignMealFromFrameEntryError,
  };
};
