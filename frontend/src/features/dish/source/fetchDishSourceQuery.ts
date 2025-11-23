import { gql } from '@apollo/client';
import { useCodegenQuery } from '../../utils/queryUtils';
import {
  useDishSourcesLazyQuery,
  useDishSourcesQuery,
  useDishSourceLazyQuery,
  useDishSourceQuery,
} from '../../../lib/graphql/generated/graphql';

export const DISH_SOURCES = gql`
  query dishSources {
    dishSources {
      id
      name
      type
    }
  }
`;

type FetchDishSourcesOnlyParams = {
  requireFetchedData?: boolean;
};

const useFetchDishSourcesOnly = (params: FetchDishSourcesOnlyParams = {}) => {
  const { requireFetchedData = false } = params;
  const { data, fetchLoading, fetchError, refetch } = useCodegenQuery(
    useDishSourcesQuery,
    useDishSourcesLazyQuery,
    requireFetchedData,
    {},
  );

  return {
    dishSources: data?.dishSources,
    fetchDishSourcesLoading: fetchLoading,
    fetchDishSourcesError: fetchError,
    refetchDishSources: refetch,
  };
};

export const DISH_SOURCE = gql`
  query dishSource($id: Int!) {
    dishSource(id: $id) {
      id
      name
      type
    }
  }
`;

type FetchDishSourceParams = {
  requireFetchedData?: boolean;
  condition?: {
    id: number;
  };
};

const useFetchDishSource = (params: FetchDishSourceParams = {}) => {
  const { condition, requireFetchedData = false } = params;
  const { data, fetchLoading, fetchError, refetch } = useCodegenQuery(
    useDishSourceQuery,
    useDishSourceLazyQuery,
    requireFetchedData,
    condition,
  );

  return {
    dishSource: data?.dishSource,
    fetchDishSourceLoading: fetchLoading,
    fetchDishSourceError: fetchError,
    refetchDishSource: refetch,
  };
};

export type FetchDishSourcesParams = {
  fetchDishSourcesOnlyParams?: FetchDishSourcesOnlyParams;
  fetchDishSourceParams?: FetchDishSourceParams;
};

export const useFetchDishSources = (params: FetchDishSourcesParams) => {
  const { fetchDishSourcesOnlyParams, fetchDishSourceParams } = params;
  const {
    dishSources,
    fetchDishSourcesLoading,
    fetchDishSourcesError,
    refetchDishSources,
  } = useFetchDishSourcesOnly(fetchDishSourcesOnlyParams || {});

  const {
    dishSource,
    fetchDishSourceLoading,
    fetchDishSourceError,
    refetchDishSource,
  } = useFetchDishSource(fetchDishSourceParams || {});

  return {
    dishSources,
    fetchDishSourcesLoading,
    fetchDishSourcesError,
    refetchDishSources,

    dishSource,
    fetchDishSourceLoading,
    fetchDishSourceError,
    refetchDishSource,
  };
};
