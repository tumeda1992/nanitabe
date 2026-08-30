import { gql } from '@apollo/client';
import { usePostponedMealsQuery } from '../../../lib/graphql/generated/graphql';
import { useCodegenQuery } from '../../utils/queryUtils';

export const POSTPONED_MEALS = gql`
  query postponedMeals {
    postponedMeals {
      id
      dishId
      dishName
      mealType
      comment
      createdAt
    }
  }
`;

export const useFetchPostponedMeals = (requireFetchedData: boolean = true) => {
  const { data, fetchLoading, fetchError, refetch } = useCodegenQuery(
    usePostponedMealsQuery,
    requireFetchedData,
  );

  return {
    postponedMeals: data?.postponedMeals ?? [],
    fetchPostponedMealsLoading: fetchLoading,
    fetchPostponedMealsError: fetchError,
    refetchPostponedMeals: refetch,
  };
};
