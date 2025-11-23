export const useCodegenQuery = (
  codegenQueryHook: ({ variables }) => any,
  codegenLazyQueryHook: ({ variables }) => any[],
  requireFetchedData: boolean = true,
  variables = {},
) => {
  const query = (() => {
    if (requireFetchedData) {
      return codegenQueryHook({ variables });
    }
    return codegenLazyQueryHook({ variables })[1];
  })();
  return {
    data: query.data,
    previousData: query.previousData,
    fetchLoading: query.loading,
    fetchError: query.error,
    refetch: query.refetch,
  };
};
