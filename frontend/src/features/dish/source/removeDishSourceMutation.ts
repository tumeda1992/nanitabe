import { gql } from '@apollo/client';
import { buildMutationExecutor } from '../../utils/mutationUtils';
import {
  RemoveDishSourceMutation,
  useRemoveDishSourceMutation,
} from '../../../lib/graphql/generated/graphql';

export const REMOVE_DISH_SOURCE = gql`
  mutation removeDishSource($dishSourceId: Int!) {
    removeDishSource(input: { dishSourceId: $dishSourceId }) {
      dishSourceId
    }
  }
`;

export const useRemoveDishSource = () => {
  const [removeDishSource, removeDishSourceLoading, removeDishSourceError] =
    buildMutationExecutor<{ dishSourceId: number }, RemoveDishSourceMutation>(
      useRemoveDishSourceMutation,
    );

  return {
    removeDishSource,
    removeDishSourceLoading,
    removeDishSourceError,
  };
};
