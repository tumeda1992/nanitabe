import { gql } from '@apollo/client';
import { buildMutationExecutor } from '../utils/mutationUtils';
import {
  SwapMealsBetweenDaysMutation,
  useSwapMealsBetweenDaysMutation,
} from '../../lib/graphql/generated/graphql';

export const SWAP_MEALS_BETWEEN_DAYS = gql`
  mutation swapMealsBetweenDays($date1: ISO8601Date!, $date2: ISO8601Date!) {
    swapMealsBetweenDays(input: { date1: $date1, date2: $date2 }) {
      updatedMealIds
    }
  }
`;

export type SwapMealsBetweenDays = {
  date1: Date;
  date2: Date;
};

export const useSwapMealsBetweenDays = () => {
  const [
    swapMealsBetweenDays,
    swapMealsBetweenDaysLoading,
    swapMealsBetweenDaysError,
  ] = buildMutationExecutor<SwapMealsBetweenDays, SwapMealsBetweenDaysMutation>(
    useSwapMealsBetweenDaysMutation,
  );

  return {
    swapMealsBetweenDays,
    swapMealsBetweenDaysLoading,
    swapMealsBetweenDaysError,
  };
};
