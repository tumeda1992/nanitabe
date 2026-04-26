import { gql } from '@apollo/client';
import * as z from 'zod';
import {
  UpdateMealFramePatternMutation,
  useUpdateMealFramePatternMutation,
} from '../../../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../../../utils/mutationUtils';
import { MEAL_FRAME_PATTERNS } from './mealFramePatternsQuery';

export const UPDATE_MEAL_FRAME_PATTERN = gql`
  mutation updateMealFramePattern($mealFramePattern: MealFramePatternForUpdate!) {
    updateMealFramePattern(input: { mealFramePattern: $mealFramePattern }) {
      mealFramePatternId
    }
  }
`;

const mealFramePatternEntrySchema = z.object({
  dayOffset: z.number().min(1, '日数は1以上で指定してください。'),
  mealType: z.number(),
  mealFrameId: z.number(),
});

const updateMealFramePatternSchema = z.object({
  mealFramePattern: z.object({
    id: z.number(),
    name: z
      .string({
        required_error: '必須項目です。',
      })
      .min(1, 'パターン名を入力してください。'),
    entries: z.array(mealFramePatternEntrySchema),
  }),
});

export type UpdateMealFramePatternInput = z.infer<typeof updateMealFramePatternSchema>;

export type UpdateMealFramePatternFunc = (
  input: UpdateMealFramePatternInput,
  mutationCallbacks: MutationCallbacks<UpdateMealFramePatternMutation>,
) => void;

export const useUpdateMealFramePattern = () => {
  const [updateMealFramePattern, updateMealFramePatternLoading, updateMealFramePatternError] =
    buildMutationExecutor<UpdateMealFramePatternInput, UpdateMealFramePatternMutation>(
      useUpdateMealFramePatternMutation,
      { refetchQueries: [{ query: MEAL_FRAME_PATTERNS }] },
    );

  return {
    updateMealFramePattern,
    updateMealFramePatternLoading,
    updateMealFramePatternError,
  };
};
