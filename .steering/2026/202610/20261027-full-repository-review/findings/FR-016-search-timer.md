# FR-016: 検索debounceが別パネルとアンマウントをまたいで残る

- 優先度: P2
- 採否: 今回は見送り（挙動維持の制約により適用取消）
- 対応状況: 適用取消・旧挙動の復元検証完了
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

- ユーザー判断: 全review指摘反映の後続指示により採用
- 適用コミット: `5319fbd`

## 適用結果（2026-11-01）

全件適用の利用者指示に基づき採用した。module共有timerをcomponentごとのuseRefへ移し、unmount時に解除する。同じパネルでは最後の入力から400ms後に検索する契約を維持した。

追加したfake timerの3ケース中、別パネル間の干渉とunmount後callbackの2ケースが修正前に失敗した。修正後は以下の検証が成功した。

- `docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand --silent DishSearchPanel ExistingDishesForRegisteringWithMeal.spec`: 3 suites / 10 tests成功。
- 同frontendの`yarn tsc --noEmit --incremental false`: 成功。
- 同frontendの`yarn lint src/components/dish/DishSearchPanel/index.tsx src/components/dish/DishSearchPanel/debounce.spec.tsx`: 違反なし。

表示構造の変更はなく、timerの時間境界・検索引数・cleanupをcomponentテストで検証した。適用commitはapplication.mdと本指摘のGit履歴で追跡する。

## 適用取消と旧挙動の復元（2026-11-05）

per-instance timerとunmount cleanupの追加を5319fbd親版の共有timerへ戻し、専用debounce specを除いた。
[復元結果](../evidence/scope-repair/fr016-attempt-1/result.md)はJest4 tests、変更fileのlint、
旧index byte一致、純抽出と利用者変更保持、diff checkが成功した。既存fixture警告は結果に保存した。
元のpanel間timer干渉と過去の検証は保存し、解消済みとは数えない。
