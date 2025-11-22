import { gql } from '@apollo/client';
import * as z from 'zod';
import { buildMutationExecutor } from '../../utils/mutationUtils';
import {
  UpdateDishSourceMutation,
  useUpdateDishSourceMutation,
} from '../../../lib/graphql/generated/graphql';
import { updateDishSourceSchema } from './schema';

export const UPDATE_DISH_SOURCE = gql`
  mutation updateDishSource($dishSource: SourceForUpdate!) {
    updateDishSource(input: { dishSource: $dishSource }) {
      dishSourceId
    }
  }
`;

const UpdateDishSourceSchema = z.object({
  dishSource: updateDishSourceSchema,
});

export type UpdateDishSource = z.infer<typeof UpdateDishSourceSchema>;

export const useUpdateDishSource = () => {
  const [updateDishSource, updateDishSourceLoading, updateDishSourceError] =
    buildMutationExecutor<UpdateDishSource, UpdateDishSourceMutation>(
      useUpdateDishSourceMutation,
    );

  return {
    updateDishSource,
    updateDishSourceLoading,
    updateDishSourceError,

    UpdateDishSourceSchema,
  };
};
