# 再発防止の文書更新案（未適用）

`tumeda-dev:doc-enricher`の提案モードで整理した。以下は追記候補であり、恒久README/docsへは反映していない。レビュー対応の実装・検証とは別に、利用者が採用する場合だけ適用する。

既存のbackend/frontendアーキテクチャ・テスト標準、food/Dish/Meal README、GraphQL mutations README、frontend features/utils READMEを読んだ。既存記述と重複せず、複数入口へ同じ判断を適用できる次の3案を残した。

## 1. 操作対象と関連先を独立して認可する

追記先: `backend/docs/ai_guideline/development_standard/application_architecture.md`。新しい「認可の境界」節に次を置く。

- **MUST**: 認証済みactorに対する権限を、操作対象と、入力が指定する各関連先で独立して確認する。対象を操作できることから関連先の利用権限を推定しない。
- 理由: 本人の食事へ他人の料理を関連付けられると、保存先は本人でも関連経由で他人の情報を取得できる。対象IDだけのscopeではこの境界を閉じられない。
- 変更ガイド: 別入口から同じCommandを呼んでも成立する認可を保ち、不正な関連IDが混在する一括操作は副作用を残さず拒否する。共有マスタのような別の権限契約まで、私有レコードの所有者一致から推定しない。

FR-002〜011の共通原因を扱う。認可はDB取得とCommand/Policyにまたがるため、一つのresolverだけを読むより先に判断条件を共有できる。

## 2. 保存確定と表示更新を別の失敗段階として扱う

追記先: `frontend/docs/ai_guideline/development_standard/application_architecture.md`。新しい「更新後の再取得と再試行」節に次を置く。

- **MUST**: 保存完了後の再取得失敗を、保存失敗と同じ再送経路へ戻さない。保存確定を保持し、表示更新だけを再試行できる状態にする。
- 理由: mutationが成功してから一覧取得に失敗する場合がある。画面が古いことを根拠にmutationを再送すると、既に登録した操作を重複実行する。
- 変更ガイド: 更新callbackのPromiseは画面の更新完了までつなぎ、保存段階と再取得段階の失敗を分けて検証する。たとえば延期登録後にカレンダー取得が失敗しても、再試行時に延期登録を再送しない。

FR-015の設計意図を全フォームへ持ち出せる原則にした。features/utils READMEのrefetchQueries設定説明は既存のまま参照し、同じ設定方法を複製しない。

## 3. 並行保証は対象DBの独立接続で検証する

追記先: `backend/docs/ai_guideline/development_standard/testing.md`。新しい「並行処理・DB制約」節に次を置く。

- **MUST**: 行ロック・一回消費・unique制約を保証する変更は、その保証を担うDBエンジンの独立接続で競合させる。SQLiteの逐次成功だけをMySQLの行ロック保証にしない。
- 理由: transactionがあることと、同じ元レコードを二要求が消費できないことは別である。接続を共有したテストや、未commitのfixtureを他接続から読ませる構成では競合自体を観測できない。
- 変更ガイド: commit済みfixture、開始/解放の同期点、有限の待ちを用意し、作成数・元行・拒否理由を確認する。後続のlock timeout/deadlockだけを期待する業務上の拒否の代わりにしない。成功時だけでなく途中失敗のrollbackも通常回帰で確認する。

FR-019とCR-004の検証契約を一般化した。具体的なMySQL fixtureの接続先・image version・観測cache間隔は変動するため、この標準へ固定せず当該spec/evidenceを正本にする。

## 選別結果

3案とも永続性・再発防止効果・複数fileを横断する非自明性・探索性・低メンテナンス・抽象レベル・既存記述との非重複（Gate A〜G）を満たすと判断した。適用するclass/methodの列挙ではなく、次回の設計判断を揃える条件を残している。

枠が食事と独立した日付/時間帯の計画であることは既存Meal READMEにあり、重複案として落とした。旧namespaceの互換委譲状態とprivate integrationの運用説明は今回の変更に必要な既存記述の修正として実施済みで、追加知識の提案とは区別する。INNODB_TRXのpoll間隔や一時検証コマンドは実装固有なので、恒久規範への昇格候補から外した。
