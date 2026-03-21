import { useAddMealFrame } from './addMealFrameMutation';
import { useFetchMealFrames } from './fetchMealFrameQuery';
import { useUpdateMealFrame } from './updateMealFrameMutation';
import { useDeleteMealFrame } from './deleteMealFrameMutation';
import { useAddMealFrameEntry } from './addMealFrameEntryMutation';
import { useRemoveMealFrameEntry } from './removeMealFrameEntryMutation';

export type { AddMealFrameInput, AddMealFrameFunc } from './addMealFrameMutation';
export type { UpdateMealFrameInput, UpdateMealFrameFunc } from './updateMealFrameMutation';
export type { DeleteMealFrameInput, DeleteMealFrameFunc } from './deleteMealFrameMutation';
export type { AddMealFrameEntryInput, AddMealFrameEntryFunc } from './addMealFrameEntryMutation';
export type { RemoveMealFrameEntryInput, RemoveMealFrameEntryFunc } from './removeMealFrameEntryMutation';

type UseMealFrameParams = {
  requireFetchedData?: boolean;
};

export default (params: UseMealFrameParams = {}) => {
  const { requireFetchedData = true } = params;

  const {
    addMealFrame,
    AddMealFrameSchema,
    addMealFrameLoading,
    addMealFrameError,
  } = useAddMealFrame();

  const {
    updateMealFrame,
    UpdateMealFrameSchema,
    updateMealFrameLoading,
    updateMealFrameError,
  } = useUpdateMealFrame();

  const {
    deleteMealFrame,
    DeleteMealFrameSchema,
    deleteMealFrameLoading,
    deleteMealFrameError,
  } = useDeleteMealFrame();

  const {
    addMealFrameEntry,
    AddMealFrameEntrySchema,
    addMealFrameEntryLoading,
    addMealFrameEntryError,
  } = useAddMealFrameEntry();

  const {
    removeMealFrameEntry,
    RemoveMealFrameEntrySchema,
    removeMealFrameEntryLoading,
    removeMealFrameEntryError,
  } = useRemoveMealFrameEntry();

  const {
    mealFrames,
    fetchMealFramesLoading,
    fetchMealFramesError,
    refetchMealFrames,
  } = useFetchMealFrames(requireFetchedData);

  return {
    addMealFrame,
    AddMealFrameSchema,
    addMealFrameLoading,
    addMealFrameError,

    updateMealFrame,
    UpdateMealFrameSchema,
    updateMealFrameLoading,
    updateMealFrameError,

    deleteMealFrame,
    DeleteMealFrameSchema,
    deleteMealFrameLoading,
    deleteMealFrameError,

    addMealFrameEntry,
    AddMealFrameEntrySchema,
    addMealFrameEntryLoading,
    addMealFrameEntryError,

    removeMealFrameEntry,
    RemoveMealFrameEntrySchema,
    removeMealFrameEntryLoading,
    removeMealFrameEntryError,

    mealFrames,
    fetchMealFramesLoading,
    fetchMealFramesError,
    refetchMealFrames,
  };
};
