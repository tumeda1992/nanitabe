import { gql } from '@apollo/client';
import * as z from 'zod';
import {
  ApplyMealFramePatternMutation,
  useApplyMealFramePatternMutation,
} from '../../../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../../../utils/mutationUtils';

export const APPLY_MEAL_FRAME_PATTERN = gql`
  mutation applyMealFramePattern($patternId: Int!, $startDate: String!) {
    applyMealFramePattern(input: { patternId: $patternId, startDate: $startDate }) {
      appliedMealFramePatternId
    }
  }
`;

const applyMealFramePatternSchema = z.object({
  patternId: z.number(),
  startDate: z.string(),
});

export type ApplyMealFramePatternInput = z.infer<typeof applyMealFramePatternSchema>;

export type ApplyMealFramePatternFunc = (
  input: ApplyMealFramePatternInput,
  mutationCallbacks: MutationCallbacks<ApplyMealFramePatternMutation>,
) => void;

export const useApplyMealFramePattern = () => {
  const [applyMealFramePattern, applyMealFramePatternLoading, applyMealFramePatternError] =
    buildMutationExecutor<ApplyMealFramePatternInput, ApplyMealFramePatternMutation>(
      useApplyMealFramePatternMutation,
    );

  return {
    applyMealFramePattern,
    applyMealFramePatternLoading,
    applyMealFramePatternError,
  };
};
