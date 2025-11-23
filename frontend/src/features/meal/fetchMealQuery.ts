import { gql } from '@apollo/client';
import { useCodegenQuery } from '../utils/queryUtils';
import {
  useMealsForCalenderLazyQuery,
  useMealsForCalenderQuery,
} from '../../lib/graphql/generated/graphql';

// export const MEAL_FRAGMENT = gql`
//   fragment Meal on Meal {
//     id
//     date
//     mealType
//     comment
//     dish {
//       ...Dish
//     }
//   }
// `;

// dish同様上記のように書きたいけどやりかたわからないからコメントアウト
export const MEALS_FOR_CALENDER = gql`
  query mealsForCalender($startDate: ISO8601Date!, $lastDate: ISO8601Date!) {
    mealsForCalender(startDate: $startDate, lastDate: $lastDate) {
      date
      meals {
        id
        date
        mealType
        comment
        dish {
          id
          name
          mealPosition
          comment
          evaluationScore
          dishSourceRelation {
            type
            sourceName
            dishSourceId
            recipeBookPage
            recipeWebsiteUrl
            recipeSourceMemo
          }
          tags {
            id
            dishId
            content
          }
        }
      }
    }
  }
`;

const truncateTimeFrom = (date: Date) => {
  // NOTE: railsに送られるときにUTCで送られるので、タイムゾーン分だけずらすようにした
  // これで送れたけど、truncateした理由が日付以外の情報除去だったから、どこまで必要かわからなくなった
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 10);
};

type FetchMealsForCalenderParams = {
  requireFetchedData?: boolean;
  startDate?: Date;
  lastDate?: Date;
};

const useFetchMealsForCalender = (params: FetchMealsForCalenderParams) => {
  const {
    requireFetchedData = false,
    startDate = null,
    lastDate = null,
  } = params;

  const { data, fetchLoading, fetchError, refetch } = useCodegenQuery(
    useMealsForCalenderQuery,
    useMealsForCalenderLazyQuery,
    requireFetchedData,
    {
      // ISO8601Dateに時間を渡すと型不正と扱われて、無限リクエストが発生するため、時間を切り捨てる
      startDate: truncateTimeFrom(startDate || new Date()),
      lastDate: truncateTimeFrom(lastDate || new Date()),
    },
  );
  return {
    mealsForCalender: data?.mealsForCalender,
    fetchMealsForCalenderLoading: fetchLoading,
    fetchMealsForCalenderError: fetchError,
    refetchMealsForCalender: refetch,
  };
};

export type FetchMealsParams = {
  fetchMealsForCalenderParams?: FetchMealsForCalenderParams;
};

export const useFetchMeals = (params: FetchMealsParams = {}) => {
  const { fetchMealsForCalenderParams } = params;

  const {
    mealsForCalender,
    fetchMealsForCalenderLoading,
    fetchMealsForCalenderError,
    refetchMealsForCalender,
  } = useFetchMealsForCalender(fetchMealsForCalenderParams || {});

  return {
    mealsForCalender,
    refetchMealsForCalender,
    fetchMealsLoading: fetchMealsForCalenderLoading,
    fetchMealsError: fetchMealsForCalenderError,
  };
};
