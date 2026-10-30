# FR-016: 検索debounceが別パネルとアンマウントをまたいで残る

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-017（現行コードで再確認）。

## 対象

- [frontend/src/components/dish/DishSearchPanel/index.tsx](../../../../../frontend/src/components/dish/DishSearchPanel/index.tsx)

## 問題と根拠

searchTimerがmodule変数で、全インスタンスが同じtimerを共有する。Bの入力がAの未実行検索をcancelし、unmount時のcleanupもないため閉じたパネルのcallbackが後から走る。

## 改善案

タイマーをuseRefでインスタンスに保持し、unmount時にclearTimeoutする。入力表示用stateと検索確定stateを分ける場合も400msの契約を確認する。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

fake timerで2パネルへの交互入力とunmountを検証する。片方の入力が他方のcallbackを消さないこと。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
