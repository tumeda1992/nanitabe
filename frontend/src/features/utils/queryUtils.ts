import { useMemo } from 'react';

// variablesがnewを含んだオブジェクトの場合、この関数を呼ぶ側でuseMemo化推奨
// fetchMealQueryが良い例で、new Dateをしていたためvariablesがエラーのたびに再生成されて無限再レンダーが起きてしまった
export const useCodegenQuery = (
  codegenQueryHook: ({ variables, skip }: { variables?: any; skip?: boolean }) => any,
  requireFetchedData: boolean = true,
  variables = {},
) => {
  const variablesForExecute = useMemo(() => variables, [variables]);

  const query = codegenQueryHook({ variables: variablesForExecute, skip: !requireFetchedData });
  return {
    data: query.data,
    previousData: query.previousData,
    fetchLoading: query.loading,
    fetchError: query.error,
    refetch: query.refetch,
  };
};
