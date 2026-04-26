import { useAddMealFramePattern } from './addMealFramePatternMutation';
import { useUpdateMealFramePattern } from './updateMealFramePatternMutation';
import { useDeleteMealFramePattern } from './deleteMealFramePatternMutation';
import { useApplyMealFramePattern } from './applyMealFramePatternMutation';
import { useFetchMealFramePatterns } from './mealFramePatternsQuery';

export type { AddMealFramePatternInput, AddMealFramePatternFunc } from './addMealFramePatternMutation';
export type { UpdateMealFramePatternInput, UpdateMealFramePatternFunc } from './updateMealFramePatternMutation';
export type { DeleteMealFramePatternInput, DeleteMealFramePatternFunc } from './deleteMealFramePatternMutation';
export type { ApplyMealFramePatternInput, ApplyMealFramePatternFunc } from './applyMealFramePatternMutation';

type UseMealFramePatternParams = {
  requireFetchedData?: boolean;
};

export default (params: UseMealFramePatternParams = {}) => {
  const { requireFetchedData = true } = params;

  const {
    addMealFramePattern,
    addMealFramePatternSchema,
    addMealFramePatternLoading,
    addMealFramePatternError,
  } = useAddMealFramePattern();

  const {
    updateMealFramePattern,
    updateMealFramePatternLoading,
    updateMealFramePatternError,
  } = useUpdateMealFramePattern();

  const {
    deleteMealFramePattern,
    deleteMealFramePatternLoading,
    deleteMealFramePatternError,
  } = useDeleteMealFramePattern();

  const {
    applyMealFramePattern,
    applyMealFramePatternLoading,
    applyMealFramePatternError,
  } = useApplyMealFramePattern();

  const {
    mealFramePatterns,
    fetchMealFramePatternsLoading,
    fetchMealFramePatternsError,
    refetchMealFramePatterns,
  } = useFetchMealFramePatterns(requireFetchedData);

  return {
    addMealFramePattern,
    addMealFramePatternSchema,
    addMealFramePatternLoading,
    addMealFramePatternError,

    updateMealFramePattern,
    updateMealFramePatternLoading,
    updateMealFramePatternError,

    deleteMealFramePattern,
    deleteMealFramePatternLoading,
    deleteMealFramePatternError,

    applyMealFramePattern,
    applyMealFramePatternLoading,
    applyMealFramePatternError,

    mealFramePatterns,
    fetchMealFramePatternsLoading,
    fetchMealFramePatternsError,
    refetchMealFramePatterns,
  };
};
