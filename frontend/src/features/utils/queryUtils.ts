// variablesがnewを含んだオブジェクトの場合、この関数を呼ぶ側でuseMemo化推奨
// fetchMealQueryが良い例で、new Dateをしていたためvariablesがエラーのたびに再生成されて無限再レンダーが起きてしまった
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
