import { gql } from '@apollo/client';
import { buildMutationExecutor } from '../../utils/mutationUtils';
import {
  BulkAddTagToDishesMutation,
  useBulkAddTagToDishesMutation,
} from '../../../lib/graphql/generated/graphql';

export const BULK_ADD_TAG_TO_DISHES = gql`
  mutation bulkAddTagToDishes($dishIds: [Int!]!, $tag: String!) {
    bulkAddTagToDishes(input: { dishIds: $dishIds, tag: $tag }) {
      dishIds
    }
  }
`;

export const useBulkAddTagToDishes = () => {
  const [bulkAddTagToDishes, loading, error] =
    buildMutationExecutor<{ dishIds: number[]; tag: string }, BulkAddTagToDishesMutation>(
      useBulkAddTagToDishesMutation,
    );
  return {
    bulkAddTagToDishes,
    bulkAddTagToDishesLoading: loading,
    bulkAddTagToDishesError: error,
  };
};
