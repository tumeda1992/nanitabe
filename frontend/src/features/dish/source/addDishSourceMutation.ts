import { gql } from '@apollo/client';
import * as z from 'zod';
import { buildMutationExecutor } from '../../utils/mutationUtils';
import {
  AddDishSourceMutation,
  useAddDishSourceMutation,
} from '../../../lib/graphql/generated/graphql';
import { newDishSourceSchema } from './schema';

export const ADD_DISH_SOURCE = gql`
  mutation addDishSource($dishSource: SourceForCreate!) {
    addDishSource(input: { dishSource: $dishSource }) {
      dishSourceId
    }
  }
`;

const AddDishSourceSchema = z.object({
  dishSource: newDishSourceSchema,
});

export type AddDishSource = z.infer<typeof AddDishSourceSchema>;

export const useAddDishSource = () => {
  const [addDishSource, addDishSourceLoading, addDishSourceError] =
    buildMutationExecutor<AddDishSource, AddDishSourceMutation>(
      useAddDishSourceMutation,
    );

  return {
    addDishSource,
    addDishSourceLoading,
    addDishSourceError,

    AddDishSourceSchema,
  };
};
