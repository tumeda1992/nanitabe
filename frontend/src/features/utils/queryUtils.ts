import { useMemo } from 'react';

// variablesがnewを含んだオブジェクトの場合、この関数を呼ぶ側でuseMemo化推奨
// fetchMealQueryが良い例で、new Dateをしていたためvariablesがエラーのたびに再生成されて無限再レンダーが起きてしまった
export const useCodegenQuery = (
  codegenQueryHook: ({ variables }) => any,
  codegenLazyQueryHook: () => any[],
  requireFetchedData: boolean = true,
  variables = {},
) => {
  const variablesForExecute = useMemo(() => variables, [variables]);

  if (!requireFetchedData) {
    // このLazyQyeryが動くかわからない。以下に対処するためだけに行った。
    // https://www.apollographql.com/docs/react/errors#%7B%22version%22%3A%223.14.0%22%2C%22message%22%3A78%2C%22args%22%3A%5B%22useLazyQuery%22%2C%22variables%22%2C%22Pass%20all%20%60variables%60%20to%20the%20returned%20%60execute%60%20function%20instead.%22%5D%7D
    // そもそもなぜLazyQueryを用意しているかというと、useMealなどで、参照系、更新系すべてを提供していて、
    // どちらの場合も同じ値を提供したく、更新系のメソッド取得時にはフェッチを行わないようにするため
    // 使うようになったら要修正
    const [execute, { data, loading, error }] = codegenLazyQueryHook();

    return {
      data,
      previousData: null,
      fetchLoading: loading,
      fetchError: error,
      refetch: () => execute({ variables: variablesForExecute }),
    };
  }

  const query = codegenQueryHook({ variables });
  return {
    data: query.data,
    previousData: query.previousData,
    fetchLoading: query.loading,
    fetchError: query.error,
    refetch: query.refetch,
  };
};
