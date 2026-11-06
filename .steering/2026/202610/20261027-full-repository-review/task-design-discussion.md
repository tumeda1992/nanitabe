# 適用範囲の再判断記録

## 2026-11-06: 正常な利用者操作・業務仕様を基準にする

利用者は「IDOR対応とかは関数の挙動を変えているだけでユーザの挙動も変わらず内部だけの話だから問題ない」と説明した。親は共通化・認可・内部不具合修正を残し、新しい業務制約と構成変更を個別判断する方針を提示し、利用者は「じゃあその方針で続けて」と指示した。その後も「切り戻し作業を止めた状態を保つなよ、続けろよ」と本体作業継続を明示した。

全関数の入力・例外・副作用まで旧版一致を要求した旧designは、この意味を過剰に狭めていた。認可強化まで取消す基準を撤回し、正常な既存業務操作に対する差分で判定する。方針検討・結果監督はSol、それ以外の実装・検証等はTerraという利用者指定を保持する。

FR-011の未commit取消を撤回し、未取消FR-002〜010を維持することは確定している。FR-012等の既存schema/UIと実装の不整合、保存値欠落、非同期待機、失敗処理、検索/タグ保存/多重消費を内部修正として復帰する。各採用範囲はdesignの操作結果に落とした。

FR-017の正数/整数検査はmealFrameIdだけが対象で、通常UIが選ぶ保存済み正整数IDを拒否しない。関数拒否差分だけで外すと再び過剰取消となるため元commit全体を復帰する。FR-034の継承は内部構造で、本人の旧入口操作を保持し他人の削除を拒否する共通化として復帰する。FR-026は既存planログパスだけへのIAM書込限定でresource構成追加がなく、正常planの保存先と整合する。offline code/testを復帰し、実AWS適用は行わない。

FR-015のPromise接続は既存callbackの意図に一致するが、追加retryボタン/エラー状態は新操作なので分離する。FR-018は日時変更時の枠解除の明文がない。FR-019は単一関係から再割当拒否までは導けずmigrationも必要。FR-023はliteral/regexpの旧仕様根拠がない。FR-028は構成・費用変更。CR-003は旧成功specの有効操作を拒否する。この6対象は親steeringの個別判断へ戻し、現在の取消状態を保つ先行scopeを確定する。

## 反映・実行区分

design/tasklistのlifecycle更新だけを本担当が行う。application/test/stage/commit/pushは実行担当へ渡す。先行範囲に未確定判断を残さず、個別判断対象を条件付き未完了taskとして混ぜない。旧24取消の実測履歴はapplication/evidenceとGitに保存する。

親から引き継いだ継続・指摘単位commit/publicationの許可を使い、形式的な再承認を追加しない。pluginの改善依頼は親の保留記録へ任せ、本体の実装再開を止める条件にしない。

## 論点1: FR-018の日付交換transactionを独立復帰する

**ステータス:** 決定

**種別:** レビュー指摘

### イテレーション1（論点1）: 枠の業務契約と原子的保存を分離する

#### 提案1（論点1）

元`25471fd`の新旧`SwapMealsBetweenDaysCommand`の`call`全体を囲む`::Meal.transaction`だけを復帰する。
取得・保存・concatの順序、返却class、current本人scopeとlegacy既存認可を維持し、後半保存失敗時は全先行保存を戻して元の例外を伝える。
枠attributesは保持し、Meal/Root/reschedule/Repository/Policy/Finderと枠解除のspecは復帰しない。
tasklistはCR-004後・全体回帰前に20Aを置き、FR-018の個別判断対象を枠解除へ限定する。

#### 検討記録（論点1・イテレーション1）

元commitの対象2pathはtransactionの囲みだけを追加しており、枠解除とは分離できる。
正常な交換の結果を変えず途中失敗の部分保存を防ぐため、既存の内部不具合修正を残す方針に一致する。
枠の扱いは今回も暫定保留とし、移動・時間帯変更・日付交換における枠の業務契約が確定した時に親steeringで再評価する。
上の初回判断でFR-018全体を取消状態とした範囲は、この決定以後、枠解除部分だけとなる。

この回はread-only提案と親Solの正式委託を事後記録したもの。
利用者が対象2pathを新たに個別承認したとの発言は補完せず、既存の正常操作維持・内部修正継続指示に対する適用判断を記録する。

[内部検討記録: 論点1・イテレーション1](internal-records/task-design-discussion.md.topic-1.md#iteration-1)

#### 提案1へのフィードバック（論点1）

**結果:** 親Solが既存継続指示の範囲として限定反映を正式委託した。

親Solのcheckpoint後の指示:

> 既存FR018read-only案を正式にdesign+planへ反映してtasklist_readyを返して。
> ユーザーの正常操作維持/内部transaction修正を採用し継続指示の範囲として既存合意を利用、再承認を新gateにしない。

CR-004 `f9a6359`後に構造編集を引き渡され、既存完了phaseを保持して20Aを挿入する。
実装・実測はexecutorへ渡し、finding/application/coverageの現在状態訂正は実測後に行う。

### 決定（論点1）

FR-018は日付交換の原子的保存だけを追加採用する。productionは新旧2Commandの`::Meal.transaction`wrapperに限定する。
両Command specで正常返却・食事/枠属性保持・空/片側空/同日・current本人scope・後半保存失敗rollbackと元例外を検証する。
枠解除は前記の業務契約確定まで親steeringで暫定保留とし、FR-019/023/028、CR-003、FR-015追加UIの保留は維持する。

## 論点2: PRのbackend CI失敗を限定修正する

**ステータス:** 決定

**種別:** レビュー指摘

### イテレーション1（論点2）: Ruby実行環境と既存認証lintを修復する

#### 提案1（論点2）

両backend workflowのrunnerを`ubuntu-24.04`に固定し、Ruby `3.3.8`を保持する。
既存の管理認証の`ENV[]`2箇所を`ENV.fetch(key, nil)`へ置き換え、既存2spec fileのstubだけを適応する。
実装5fileに限定し、runnerとlint記法を別commitにする。local全RSpec/全RuboCop/YAML parseと、push後のPR上の両CI本体成功を確認する。

#### 検討記録（論点2・イテレーション1）

親Solが取得した両job logでは、Ruby `3.3.8`が`ubuntu-26.04`で利用できず、本体前に失敗していた。
公式setup-rubyの旧patch対応に従いrunnerを固定すれば、既存Rubyと依存を変えずに実行可能となる。
その後の既知lint 2件は既定nil付きfetchへ変えれば未設定/空文字・正誤credentialの意味を保てる。
認証機能のFR-001保留、その他業務判断、保護3file、実環境禁止を保持する。
記法修正を写すだけの新testは不要であり、既存認証/管理CRUDと全回帰で確認する。

この回は親Solから受領した調査結果と限定方針の事後記録である。
本担当は対象5fileを読み、追加の業務判断が不要なことを確認した。CI本体の成功は実装後に測定する。

[内部検討記録: 論点2・イテレーション1](internal-records/task-design-discussion.md.topic-2.md#iteration-1)

#### 提案1へのフィードバック（論点2）

**結果:** 利用者の失敗指摘に対する限定followupとして親Solが設計反映を委託した。

利用者の原文:

> PR見たらbackendのテストもrubocopも落ちてるけど

親Solの委託:

> CIを本体実行/成功まで直すことを新ユーザーfeedbackの対応として進める。
> 追加ユーザー承認gate不要、既承認gitadd/commit/push/dockercompose利用。

### 決定（論点2）

designのCI followupとtasklist末尾22へ限定5fileの修復、2原因別commit、local全回帰、PRの最新sourceに対する両CI本体成功を追加する。
source `3d832f5`の旧検証と既存完了phaseは保持し、新sourceの検証結果をREADME/application/coverageとPR説明の後続記録へ結ぶ。
実装はTerra、test-runnerのphysical ownerは親Sol。FR-001認証機能と他項目の保留、保護3file、実環境禁止を継続し、plugin保留3件の解除は含めない。
