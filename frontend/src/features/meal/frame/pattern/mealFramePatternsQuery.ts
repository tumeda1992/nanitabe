import { gql } from '@apollo/client';
import { useMealFramePatternsQuery } from '../../../../lib/graphql/generated/graphql';
import { useCodegenQuery } from '../../../utils/queryUtils';

export const MEAL_FRAME_PATTERNS = gql`
  query mealFramePatterns {
    mealFramePatterns {
      id
      name
      entries {
        id
        dayOffset
        mealType
        mealFrameId
        mealFrameName
      }
    }
  }
`;

export const useFetchMealFramePatterns = (requireFetchedData: boolean = true) => {
  const { data, previousData, fetchLoading, fetchError, refetch } = useCodegenQuery(
    useMealFramePatternsQuery,
    requireFetchedData,
  );

  return {
    mealFramePatterns: (data ?? previousData)?.mealFramePatterns ?? [],
    fetchMealFramePatternsLoading: fetchLoading,
    fetchMealFramePatternsError: fetchError,
    refetchMealFramePatterns: refetch,
  };
};
