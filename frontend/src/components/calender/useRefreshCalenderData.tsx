import { useApolloClient } from '../../lib/graphql/buildApolloClient';

export default (args: { refetchMealsForCalender: any }) => {
  const { refetchMealsForCalender } = args;
  const { apolloClient } = useApolloClient();

  const refreshData = async () => {
    /*
          これはオーバーキルな対応で、本来こうはしたくない。

          本来したいこと: 追加・更新が起きた後にデータを取得する際はネットワーク経由で情報を再度取得する
          該当ケース: addMealWithNewDishでdish追加後、addMealで使う既存dish一覧が更新されていてほしい
          なぜ難しいか: 古いデータのグローバルデータであるキャッシュのうまい消し方を知らない

          個別の方法
          - データ追加・更新時に当該データのキャッシュを消す
            - 多分これが本筋で、キャッシュの消し方を知ったらこれを行う
          - apollo経由のデータを使うコンポーネントの初回描画時にキャッシュ経由のデータ取得なら当該データの再取得
            - キャッシュ経由データ取得だったか判断できない
         */
    // テストが通らないので仕方なく
    if (apolloClient?.clearStore !== undefined) {
      await apolloClient.clearStore();
    }
    refetchMealsForCalender();
  };

  return {
    refreshData,
  };
};
