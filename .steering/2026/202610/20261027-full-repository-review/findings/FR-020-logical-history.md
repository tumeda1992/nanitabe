# FR-020: Nextの画面遷移で論理URLが更新されず日付がずれる

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [frontend/src/app/logical-history.tsx](../../../../../frontend/src/app/logical-history.tsx)
- [frontend/src/components/calendar/calendarComponents/CalendarHeader/index.tsx](../../../../../frontend/src/components/calendar/calendarComponents/CalendarHeader/index.tsx)
- [frontend/src/app/calendar/month/[date]/page.tsx](../../../../../frontend/src/app/calendar/month/[date]/page.tsx)

## 問題と根拠

ProviderはusePathnameを初期stateにしか使わず、以降は独自pushHistoryとpopstateだけで更新する。週/月切替や今週リンクはNext Linkを使い、共通layout内のProviderは維持される。この遷移で論理URLが旧ページのままなら新ページのパーサーが不一致として今日へ戻る。Jestでpathname変更後も古い論理URLが返ることを実測した。実ブラウザのNext遷移は未検証。

## 改善案

Nextのpathname/searchの変更を論理stateへ同期するか、カレンダーの表示日付の正本をrouterへ統一する。独自pushStateと戻る/進むによる二重更新を回帰テストで防ぐ。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

今日以外の週から同じ日を含む月への切替、今週リンク、戻る/進むを検証する。Provider単体の同期欠落は実測済み。

追加検証で問題の現行挙動を再現した。テスト成功は修正済みを意味しない。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
