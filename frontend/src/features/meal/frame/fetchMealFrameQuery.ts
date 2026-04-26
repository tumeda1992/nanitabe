import { gql } from '@apollo/client';
import { useMealFramesQuery } from '../../../lib/graphql/generated/graphql';
import { useCodegenQuery } from '../../utils/queryUtils';

export const MEAL_FRAMES = gql`
  query mealFrames {
    mealFrames {
      id
      name
    }
  }
`;

export const useFetchMealFrames = (requireFetchedData: boolean = true) => {
  const { data, fetchLoading, fetchError, refetch } = useCodegenQuery(
    useMealFramesQuery,
    requireFetchedData,
  );

  return {
    mealFrames: data?.mealFrames ?? [],
    fetchMealFramesLoading: fetchLoading,
    fetchMealFramesError: fetchError,
    refetchMealFrames: refetch,
  };
};
