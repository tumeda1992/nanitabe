import { gql } from '@apollo/client';
import { buildMutationExecutor } from '../utils/mutationUtils';
import {
  RemoveDishMutation,
  useRemoveDishMutation,
} from '../../lib/graphql/generated/graphql';

export const REMOVE_DISH = gql`
  mutation removeDish($dishId: Int!) {
    removeDish(input: { dishId: $dishId }) {
      dishId
    }
  }
`;

export const useRemoveDish = () => {
  const [removeDish, removeDishLoading, removeDishError] =
    buildMutationExecutor<{ dishId: number }, RemoveDishMutation>(
      useRemoveDishMutation,
    );

  return {
    removeDish,
    removeDishLoading,
    removeDishError,
  };
};
