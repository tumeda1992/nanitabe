# 内部検討記録: 論点1 — 食事の日付交換transactionだけを復帰するか

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点1

## 開始context

正常な既存業務操作を保ち、認可・内部の不具合修正を残す継続指示がある。
既存designはFR-018を全体保留としていたが、元commitには枠解除と交換全体のtransactionが含まれる。
枠の業務契約を選ばずに独立採用できる差分があるかを調べた。
この記録はread-only提案と親Solからの反映指示後の事後記録であり、調査前に保存したものではない。

<a id="iteration-1"></a>

## イテレーション1: 原子的保存を枠解除から分離する

<a id="iteration-1-record-1"></a>

### 判断: 2Commandのwrapper復帰は正常操作を保つか

原子的保存だけの復帰は既存方針に一致する。根拠は元`25471fd`と現在版の2Commandの照合である。
`backend/app/domain/business/food/meal/usecase/swap_meals_between_days_command.rb`と
`backend/app/domain/business/dish/meal/command/swap_meals_between_days_command.rb`の元差分は、
既存call全体を`::Meal.transaction`で囲むだけであり、fetch・保存・concatの順序と引数を変えない。

成立条件は正常な交換結果を保ち、後半保存失敗時に前半のDB保存を戻すこと。
currentは`Meal.fetch_by_date(date, user_id:)`、legacyは日付だけの取得と`Repository.update`内の認可を維持する。
GraphQL resolverは既に外側transactionを持つが、Command直接呼出しも原子的にする意味がある。

現Meal/Repositoryは枠を更新しないため、wrapperだけなら関連枠の全属性を保持できる。
元frame_release_spec全体の復帰は枠解除を採用することになるため、この案には含めない。
Meal/Root/reschedule/Repository/Policy/FinderとFR-019 migrationは対象外である。

検証は新旧Command specで正常返却class/順序・食事属性・枠snapshot・空/片側空/同日を確認する。
後半保存で特定の例外instanceを発生させ、前半が実保存されたことと、全Meal/枠のreload結果が実行前へ戻ることを確認する。
current本人scopeとlegacy既存認可も維持する。transaction呼出mockだけでは原子的保存の証拠にならない。

本担当のread-only案に対し、親SolはCR-004後checkpointでdesign/tasklistへ反映する方針を示し、
CR-004 `f9a6359`後に限定編集を正式委託した。利用者がこの2pathを個別承認したという追加発言は確認していない。
採用根拠は利用者の既存方針・継続指示と、親Solのその範囲内での適用判断である。
testは本担当では未実行。application/test/Git index/commit/pushは変更せず、実測をexecutorへ渡す。

### 設計・planの引渡し確認

親Solが最終確認を引き継いだ。design、tasklist、議論、内部記録の差分と相互参照を読み、作成・更新時のdocument-review観点で、限定2pathの実装、実保存rollbackの採点方法、枠解除の保留理由と再評価条件を実行担当が判別できることを確認した。公開環境の実値や追加の業務判断は含まない。内容上の指摘なし。
補助検査の`spawnSync git EPERM`は既存承認済みの実行経路で再検査し、HEADのphase 1〜20とのbyte一致と完了チェック61個の保持を確認した。discussion構造検査は問題0、差分検査も成功。原子的保存の設計と20Aを実行担当へ返し、実装・testは未実施として引き継ぐ。
