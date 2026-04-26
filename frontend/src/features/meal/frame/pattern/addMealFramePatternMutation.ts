import { gql } from '@apollo/client';
import * as z from 'zod';
import {
  AddMealFramePatternMutation,
  useAddMealFramePatternMutation,
} from '../../../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../../../utils/mutationUtils';
import { MEAL_FRAME_PATTERNS } from './mealFramePatternsQuery';

export const ADD_MEAL_FRAME_PATTERN = gql`
  mutation addMealFramePattern($mealFramePattern: MealFramePatternForCreate!) {
    addMealFramePattern(input: { mealFramePattern: $mealFramePattern }) {
      mealFramePatternId
    }
  }
`;

const mealFramePatternEntrySchema = z.object({
  dayOffset: z.number().min(1, '日数は1以上で指定してください。'),
  mealType: z.number(),
  mealFrameId: z.number(),
});

const addMealFramePatternSchema = z.object({
  mealFramePattern: z.object({
    name: z
      .string({
        required_error: '必須項目です。',
      })
      .min(1, 'パターン名を入力してください。'),
    entries: z.array(mealFramePatternEntrySchema),
  }),
});

export type AddMealFramePatternInput = z.infer<typeof addMealFramePatternSchema>;

export type AddMealFramePatternFunc = (
  input: AddMealFramePatternInput,
  mutationCallbacks: MutationCallbacks<AddMealFramePatternMutation>,
) => void;

export const useAddMealFramePattern = () => {
  const [addMealFramePattern, addMealFramePatternLoading, addMealFramePatternError] =
    buildMutationExecutor<AddMealFramePatternInput, AddMealFramePatternMutation>(
      useAddMealFramePatternMutation,
      { refetchQueries: [{ query: MEAL_FRAME_PATTERNS }] },
    );

  return {
    addMealFramePattern,
    addMealFramePatternSchema: addMealFramePatternSchema,
    addMealFramePatternLoading,
    addMealFramePatternError,
  };
};
