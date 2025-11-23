import { gql } from '@apollo/client';
import {
  useExistingDishesForRegisteringWithMealLazyQuery,
  useDishesPerSourceLazyQuery,
  useDishesPerSourceQuery,
  useExistingDishesForRegisteringWithMealQuery,
  useDishQuery,
  useDishLazyQuery,
  ExistingDishesForRegisteringWithMealDocument,
} from '../../lib/graphql/generated/graphql';
import { useCodegenQuery } from '../utils/queryUtils';

// Dishを使うフラグメントが出てきたらコメントアウトを外して使用
//
// 本当はdishと同様のスキーマを持つところで使いまわしたいんだけど、
// zodのbrandのようにスキーマが同じでも命名が違うものはフラグメントとして使い回せるものではないらしい。
// というか、fragment xx on oo のooに当てはまるもの以外を置けない
//
// export const DISH_FRAGMENT = gql`
//   fragment Dish on Dish {
//     id
//     name
//     mealPosition
//     comment
//   }
// `;

export const EXISTING_DISHES_FOR_REGISTERING_WITH_MEAL = gql`
  query existingDishesForRegisteringWithMeal(
    $dishIdRegisteredWithMeal: Int
    $searchString: String
    $mealPosition: Int
    $registeredWithMeal: Boolean
  ) {
    existingDishesForRegisteringWithMeal(
      dishIdRegisteredWithMeal: $dishIdRegisteredWithMeal
      searchString: $searchString
      mealPosition: $mealPosition
      registeredWithMeal: $registeredWithMeal
    ) {
      id
      name
      mealPosition
      comment
      dishSourceName
      evaluationScore
    }
  }
`;

type FetchExistingDishesForRegisteringWithMealParams = {
  requireFetchedData?: boolean;
  dishIdRegisteredWithMeal?: number | null;
  searchString?: string | null;
  mealPosition?: number | null;
  registeredWithMeal?: boolean | null;
};

const useFetchExistingDishesForRegisteringWithMeal = (
  params: FetchExistingDishesForRegisteringWithMealParams = {},
) => {
  const {
    requireFetchedData = false,
    dishIdRegisteredWithMeal = null,
    searchString = null,
    mealPosition = null,
    registeredWithMeal = null,
  } = params;
  const { data, previousData, fetchLoading, fetchError, refetch } =
    useCodegenQuery(
      useExistingDishesForRegisteringWithMealQuery,
      useExistingDishesForRegisteringWithMealLazyQuery,
      requireFetchedData,
      {
        dishIdRegisteredWithMeal,
        searchString,
        mealPosition,
        registeredWithMeal,
      },
    );

  return {
    existingDishesForRegisteringWithMeal:
      data?.existingDishesForRegisteringWithMeal,
    prefetchedExistingDishesForRegisteringWithMeal:
      previousData?.existingDishesForRegisteringWithMeal,
    fetchExistingDishesForRegisteringWithMealLoading: fetchLoading,
    fetchExistingDishesForRegisteringWithMealError: fetchError,
    refetchExistingDishesForRegisteringWithMeal: refetch,
  };
};

export const DISH = gql`
  query dish($id: Int!) {
    dish(id: $id) {
      id
      name
      mealPosition
      comment
      dishSourceRelation {
        dishSourceId
        recipeBookPage
        recipeWebsiteUrl
        recipeSourceMemo
      }
      tags {
        id
        content
      }
    }
  }
`;

type FetchDishParams = {
  requireFetchedData?: boolean;
  condition?: {
    id: number;
  };
};

const useFetchDish = (params: FetchDishParams = {}) => {
  const { condition, requireFetchedData = false } = params;
  const { data, fetchLoading, fetchError, refetch } = useCodegenQuery(
    useDishQuery,
    useDishLazyQuery,
    requireFetchedData,
    condition,
  );

  return {
    dish: data?.dish,
    fetchDishLoading: fetchLoading,
    fetchDishError: fetchError,
    refetchDish: refetch,
  };
};

export const DISHES_PER_SOURCE = gql`
  query dishesPerSource {
    dishesPerSource {
      dishSource {
        id
        name
        type
      }
      dishesPerMealPosition {
        mealPosition
        dishes {
          id
          name
          mealPosition
          comment
          meals {
            id
          }
        }
      }
    }
  }
`;

type FetchDishesPerSourceParams = {
  requireFetchedData?: boolean;
};

const useFetchDishesPerSource = (params: FetchDishesPerSourceParams) => {
  const { requireFetchedData = false } = params;
  const { data, fetchLoading, fetchError, refetch } = useCodegenQuery(
    useDishesPerSourceQuery,
    useDishesPerSourceLazyQuery,
    requireFetchedData,
  );

  return {
    dishesPerSource: data?.dishesPerSource,
    fetchDishesPerSourceLoading: fetchLoading,
    fetchDishesPerSourceError: fetchError,
    refetchDishesPerSource: refetch,
  };
};

export type FetchDishesParams = {
  fetchExistingDishesForRegisteringWithMealParams?: FetchExistingDishesForRegisteringWithMealParams;
  fetchDishParams?: FetchDishParams;
  fetchDishesPerSourceParams?: FetchDishesPerSourceParams;
};

export const useFetchDishes = (params: FetchDishesParams) => {
  const {
    fetchExistingDishesForRegisteringWithMealParams,
    fetchDishParams,
    fetchDishesPerSourceParams,
  } = params;
  const {
    existingDishesForRegisteringWithMeal,
    prefetchedExistingDishesForRegisteringWithMeal,
    fetchExistingDishesForRegisteringWithMealLoading,
    fetchExistingDishesForRegisteringWithMealError,
    refetchExistingDishesForRegisteringWithMeal,
  } = useFetchExistingDishesForRegisteringWithMeal(
    fetchExistingDishesForRegisteringWithMealParams || {},
  );

  const {
    dishesPerSource,
    fetchDishesPerSourceLoading,
    fetchDishesPerSourceError,
    refetchDishesPerSource,
  } = useFetchDishesPerSource(fetchDishesPerSourceParams || {});

  const { dish, fetchDishLoading, fetchDishError, refetchDish } = useFetchDish(
    fetchDishParams || {},
  );

  return {
    existingDishesForRegisteringWithMeal,
    prefetchedExistingDishesForRegisteringWithMeal,
    dish,
    dishesPerSource,

    fetchLoading:
      fetchExistingDishesForRegisteringWithMealLoading ||
      fetchDishesPerSourceLoading ||
      fetchDishLoading,
    fetchError:
      fetchExistingDishesForRegisteringWithMealError ||
      fetchDishesPerSourceError ||
      fetchDishError,

    refetchExistingDishesForRegisteringWithMeal,
    refetchDish,
    refetchDishesPerSource,
  };
};
