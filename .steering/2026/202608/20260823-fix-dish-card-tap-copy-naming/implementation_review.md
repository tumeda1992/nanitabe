# 議論記録

<!--
本fileの非準拠（提案Nへ原因追跡を入れ、満たす必要のある条件を欠落させた）については、
一般則の側をplugin正本repositoryへ引き渡した。`escalate-plugin-skill-fix` 経由。

- 正本側のsteering directory: `20260827-fix-implementation-review-trigger`
- 引き渡した提案: steering skillの実装完了後reviewのtrigger条件節「直接受け取った」が、
  assistant自身が発見した不具合で発火しない問題を直す

議論の続きは正本repository側の記録が正である。本fileには続きを書き足さない。
-->

## 論点1: 改名の影響範囲調査で参照元を1件見落とした

**ステータス:** 決定

**種別:** 認識齟齬

### イテレーション0: design.md の影響範囲記述を実測へ合わせる

#### 提案0

`design.md` の「前提とする既存仕様」にある呼び出し元の記述を、実測に合わせて置き換える。

```diff
-- `frontend/src/components/calendar/calendarComponents/DateCard.tsx`: `DishCard` の唯一の呼び出し元。
+- `frontend/src/components/calendar/calendarComponents/DateCard.tsx`: `MealCard` componentの呼び出し元。
+- `frontend/src/components/dish/DishSearchCard/index.tsx`: `MealCard/CategoryIcon` を再利用している。component本体ではなく配下のfileへの依存であり、ディレクトリ改名の影響を受ける。
```

「唯一の」という限定を外す。component識別子の参照とディレクトリ配下fileへのpath依存は別の依存であり、後者を数えていなかったことがこの誤りの実体である。

skillとdocsは変更しない。`tasklist.md` も変更しない。Phase 4 の残存確認taskは既に実測結果を反映済みである。

#### 提案背景

##### 事象

`design.md` に「`DateCard.tsx`: `DishCard` の唯一の呼び出し元」と書いたが誤りだった。`frontend/src/components/dish/DishSearchCard/index.tsx` が `CategoryIcon` を `../../calendar/calendarComponents/DishCard/CategoryIcon` からimportしていた。

executorがsession limitで停止した時点で、この参照が旧pathのまま残りビルドが壊れていた。tasklist Phase 4 の「残存確認」で `git grep -n "DishCard\|dishCard-"` を実行して検出し、修正した。

##### 原因

設計時に使った次のcommandが原因である。

```bash
grep -rn "DishCard" src | grep -v "calendarComponents/DishCard/"
```

`grep -v` は「そのdirectory配下のfileを除外する」意図で書いたが、実際には**行の内容**に対して働く。`DishSearchCard/index.tsx` のimport行は文字列として `calendarComponents/DishCard/` を含むため、除外側にマッチして消えた。

対象directory配下のfileを除外したいなら、path指定で行う。

```bash
git grep -n "DishCard" -- 'frontend/src' ':!frontend/src/components/calendar/calendarComponents/DishCard'
```

##### 原因owner

**成果物固有**と分類する。今回のcommandの組み立てが誤っていた。

skillの不足ではない。`task-design/SKILL.md` Step 0.75 は「類似実装を検索し、少なくとも次を確認する」として検索を求めているが、検索commandの正しさまでは規定していない。規定すべき性質のものでもない。

repository知識の不足でもない。`DishSearchCard` が `CategoryIcon` を再利用している事実は、正しいcommandを打てば1回で分かる。

##### 検出できた構造は維持されている

tasklist Phase 4 に「`git grep` で残存が gitignore 対象だけであることを確認する」という機械的なtaskを置いていた。設計時の調査が漏れても実行時の機械的確認が拾える構造になっており、実際に機能した。この構造は既にあるため、追加のruleを設けない。

##### 提案0が満たす必要のある条件

1. `design.md` の記述が実測と一致する
2. 「唯一の」という検証していない限定を残さない
3. component識別子の参照とpath依存が別物であることが読み取れる
4. 既に機能している機械的確認の構造へ手を加えない

diffの1行目の削除が条件2、2行目と3行目の追加が条件1と条件3、skill・docs・tasklistを変更しないことが条件4を満たす。

#### 提案0へのフィードバック

**結果:** 受諾。

> ok

### 決定

`design.md` の「前提とする既存仕様」から「唯一の」という限定を外し、`DishSearchCard/index.tsx` が `MealCard/CategoryIcon` へpath依存している事実を追記する。component識別子の参照とディレクトリ配下fileへのpath依存を別の依存として書き分ける。

原因owner は成果物固有とする。`grep -v` が行の内容へ働くことを踏まえずcommandを組み立てたことが実体であり、skillもrepository知識も変更しない。

`tasklist.md` Phase 4 の `git grep` による残存確認が設計時の漏れを実際に検出したため、検出構造の上に新しいruleを重ねない。

## 論点2: Phase 2 の実機確認タスクが実行不能だった

**ステータス:** 決定

**種別:** レビュー指摘

### イテレーション0: 到達不能な検証タスクの扱いを決める

#### 提案0

`tasklist.md` Phase 2 の `visual-inspector` タスクを取消完了にする。

```markdown
- [x] ~~`visual-inspector`で実機確認する~~（実行不能により取消: 実機のUIから「モーダルを開いたまま親を再renderさせる」操作へ到達できない。`calendar`と`features/meal`にresize・polling・interval等の再render契機が存在しないことを確認済み。この機構の検証はjsdomの回帰テストが所有する）
```

取消理由は「依存関係の変更により元taskが不要または実行不能になった」に該当させる。時間不足、難しさ、host停止、tool制限、外部環境未準備のいずれも理由にしない。

Phase 2 の DoD からも、実機確認に相当する行を外す。残るDoDは次の2つとする。

- カードと無関係な親のstate変化で再renderが起きても、開いている評価モーダルの選択スコアが保持される（jsdom回帰テストで検証）
- `useFullScreenModal` を使う他の4箇所を変更せずに、それぞれの既存specがgreenのままである

skillは変更しない。

#### 提案背景

##### 事象

`tasklist.md` Phase 2 の DoD と Tasks に `visual-inspector` による実機確認を置いた。確認内容は「カードと無関係な親の state 変化で再render が起きても、開いている評価モーダルの選択スコアが保持される」である。

`visual-inspector` が実行した結果、この操作は実機の UI から到達できないと分かった。`frontend/src/components/calendar` と `frontend/src/features/meal` を grep しても、resize、polling、interval 等の自動再render契機が存在しない。モーダルを開いたまま親を再render させる UI 操作が無い。

##### 原因

**成果物固有**と分類する。tasklist を書いた時点で、その検証が実機から到達可能かを確認していなかった。

jsdom では親componentをテスト内で定義して再renderを起こせる。その体験をそのまま実機の検証手順へ持ち込み、実機に同じ契機があるかを確かめなかった。

`tasklist-design.md` は「UIの見た目に関わる変更があるphaseでは、そのphaseのDoDへscreenshot確認taskを含める」と規定しており、これに従った結果である。規定自体は誤っていない。誤っていたのは、規定を適用する際に**その検証が実機から到達可能か**を問わなかったことである。

##### skill変更を提案しない理由

「この検証手順を、実機の UI 操作だけで到達できるか」という観点を `tasklist-design.md` へ足す案を検討した。今回は提案しない。

同種の事例が一度しか観測されておらず、一般則として書くには根拠が薄い。今回は成果物固有として扱い、同種の事例がもう一度出たときに skill 不足として扱い直す余地を残す。

##### 提案0が満たす必要のある条件

1. 取消理由が `tasklist.md` の取消条件に該当し、禁止された理由を使っていない
2. この機構の検証をどの層が所有するかが記録に残る
3. DoDに到達不能な条件が残らない
4. 根拠の薄い一般則をskillへ足さない

取消理由の文面が条件1と条件2、DoDから実機確認行を外すことが条件3、skill変更を提案しないことが条件4を満たす。

#### 提案0へのフィードバック

**結果:** 受諾。

> ok

**事後記録である。** この合意はchat上で先に成立し、`tasklist.md`への取消反映も同時に行った。その後に本fileを意味構造へ再編したため、提案と背景の記述は合意時点より後に整えたものである。決定内容そのものは合意時から変わっていない。

### 決定

`tasklist.md` Phase 2 の `visual-inspector` taskを「実行不能により取消」として完了させ、取消理由を task 行へ残す。Phase 2 の DoD から実機確認に相当する行を外し、残るDoDを2つとする。反映済みである。

取消理由は「依存関係の変更により元taskが不要または実行不能になった」に該当させる。時間不足、難しさ、host停止、tool制限、外部環境未準備のいずれも理由にしない。

skillは変更しない。同種の事例が一度しか観測されておらず、一般則として `tasklist-design.md` へ書くには根拠が薄い。同種の事例がもう一度出た時点で、skill不足として扱い直す。

## 論点3: remount 修正の根拠の述べ方を訂正するか

**ステータス:** 決定

**種別:** 認識齟齬

### イテレーション0: 「機構の再現」と「到達可能な経路」の区別を記述へ反映する

#### 提案0

`design.md` の「調査で確定した原因」へ、実測の射程を明示する一文を追加する。

```diff
 ### 実測1: jsdom（`spike.repro.spec.tsx`、コンテナ内 Jest）
+
+jsdomの実測は、機構が再現することを示す。実機のUI操作から到達できる経路があることは別に確認する必要がある。本repositoryで実機から到達できるのは実測2のbubbling経路であり、親の再render経路については、`calendar`と`features/meal`にresize・polling・interval等の自動再render契機が存在しないことを確認した。
```

`task-design-discussion.md` 論点1 のイテレーション0は feedback 確定済みであるため、過去 iteration へ手を加えない。訂正は本論点が所有する。

論点1の決定そのものは撤回しない。修正は正しく、差分は `useCallback` の追加と ref 一つで、回帰テストで固定済みである。

#### 提案背景

##### 事象

`task-design-discussion.md` 論点1 の提案背景で、実測3を根拠に次のように書いた。

> 引き金だけ直すと、今回の症状は消えるが、`useFullScreenModal` を使う全5箇所で親の再renderによる入力消失が残る

実測3が確認したのは、jsdom で親componentを定義して再renderを起こしたときに機構が再現することである。実機で到達可能な経路があることは確認していない。挙げていた「`FrameCard` の `AddMeal` フォーム中に Apollo cache 更新で再render」という経路は、検証していない推論である。

##### 原因

**成果物固有**と分類する。今回の記述が、確認した範囲を超えて断定していた。

skillの不足ではない。`task-design/SKILL.md` は「調査で得た事実と、そこから導く設計判断を分離する」と規定しており、この規定に従えていなかっただけである。

##### なぜ記録するか

この steering では一貫して「推論を実測として扱わない」ことを守ってきた。原因究明では jsdom の対照実験と実機再現の両方を取り、CSS が原因でないことも実測で示した。

その同じ steering の中で、修正の必要性を述べる段では「jsdom で再現した」と「実機で起こりうる」を区別せずに書いた。区別を要求する側と、区別を緩めた側が同じ文書の中にある。この非対称を記録に残す。

##### 論点2と分けた理由

論点2は tasklist の task 状態を扱い、本論点は過去の記述の射程を扱う。片方だけを採ることができるため、独立した decision として分けた。

##### 提案0が満たす必要のある条件

1. `design.md` を読んだ人が、jsdomの実測がどこまでを示すかを取り違えない
2. feedback確定済みの過去iterationへ手を加えない
3. 論点1の決定そのものを揺らさない

追加する一文が条件1、訂正を本論点が所有すると明記することが条件2、決定を撤回しないと明記することが条件3を満たす。

#### 提案0へのフィードバック

**結果:** 受諾。提案0のまま採る。

> 提案0のみで

agentが併せて提示した「`spike.repro.spec.tsx`は削除済みであり、現在の正本は`MealCard/index.spec.tsx`である」という追記案は不採用とする。

### 決定

`design.md` の「調査で確定した原因」の実測1見出し直後へ、実測の射程を明示する一文を追加する。追加する内容は提案0のdiffのとおりとし、それ以上の追記はしない。

`task-design-discussion.md` 論点1 のイテレーション0はfeedback確定済みであるため、過去iterationへ手を加えない。訂正は本論点が所有する。

論点1の決定そのものは撤回しない。修正内容は正しく、回帰テストで固定済みである。

原因ownerは成果物固有とする。`task-design/SKILL.md` は既に「調査で得た事実と、そこから導く設計判断を分離する」と規定しており、skillの不足ではない。

---

## 論点4: 動作確認の実施主体がtasklistとユーザーの恒常指示で食い違う

**ステータス:** 決定

**種別:** 認識齟齬

### イテレーション0: 動作確認の順序と、ユーザー確認gateの閉じ方を決める

#### 提案0

`frontend/docs/ai_guideline/development_standard/testing.md` へ、UI変更の動作確認の順序を追記する。

```markdown
## UI変更の動作確認

順序を固定する。

1. agentが `visual-inspector` で動作確認を行い、観測結果とスクリーンショットを報告する
2. ユーザーは報告を見たうえで、必要と判断したときだけ自分で触る
3. commit・push・PRは、ユーザーが報告を受けて進めてよいと述べた時点で可能になる

- **禁止**: 自分で確認せずに「確認してください」とユーザーへ促すこと
- **禁止**: agentの機械的確認をもって、ユーザーが進めてよいと述べる前にcommit・push・PRへ進むこと

やってしまいがちな失敗: 「ユーザー動作確認が必須」という規定を読み、agent自身の確認を省いて
ユーザーへ確認を依頼する。ユーザーの手番が先に来てしまい、agentが観測できたはずの不具合が
ユーザーの時間を使って発見される。
```

併せて `tasklist.md` の動作確認taskの取消表現を、この読みに合わせて次へ置き換える。

```markdown
- [x] ~~ユーザーへ動作確認を依頼する~~（取消: agentが先に確認して報告する順序のため、依頼という形を取らない。ユーザー確認gate自体は廃止せず、報告を受けたユーザーが進行を述べた時点で満たす）
```

pluginのskillは変更しない。

#### 提案背景

##### 事象

`tasklist.md` の動作確認phaseは、DoDが「ユーザーが実際に……確認した」、Tasksが「ユーザーに動作確認を依頼する」と書かれていた。

一方でユーザーの恒常指示は「修正・実装後に『確認してください』とユーザーに促すのは禁止」「Playwrightスクリプトを作成して自分で確認してから結果を報告する」である。

今回agentは `visual-inspector` で3点を確認し、依頼taskを取消として扱った。この取消が妥当かどうかが未決である。

##### 二つの規定は矛盾していない

pluginの `tasklist-design.md` は次を規定している。

> 自動testとscreenshotは機械的確認であり、ユーザーが実際に触る動作確認を代替しない。commit・push・PRより前にユーザー動作確認を必須にする。

ユーザーの恒常指示は「促すな」であって「ユーザー確認を廃止しろ」ではない。両者は順序の規定として読める。agentが先に確認して報告し、ユーザーは報告を見たうえで判断する。gateはユーザーが進行を述べた時点で閉じる。

矛盾に見えたのは、tasklistがこの順序を「依頼する」という一語へ畳んだためである。依頼はユーザーの手番を先に置く表現であり、agentの確認が先だという順序が消える。

##### 原因owner

**repository知識**と分類する。

この順序はユーザーの恒常指示としてのみ存在し、repositoryのdocsに書かれていない。`forbidden-actions.md` は `visual-inspector` の経由を義務付けているが、これは手段の指定であって、誰がいつ確認するかという順序を規定していない。

したがって次のsessionのagentも、pluginのtemplateどおりに「ユーザーに動作確認を依頼する」と書き、同じ齟齬を起こす。

##### skillを変更しない理由

pluginは利用先を問わないskillである。「agentが先に確認する」という順序は、実行環境にブラウザ自動化があり、agentが実際に画面を触れる利用先でのみ成立する。それが無い利用先では、ユーザーへ確認を仰ぐ以外の手段がない。

`tasklist-design.md` の規定はユーザー確認gateの存在を定めており、これは今回の決定でも維持される。skillの不足ではない。

##### 提案0が満たす必要のある条件

1. 次のsessionのagentが、docsを読むだけで動作確認の順序を判断できる
2. ユーザー確認gateを廃止しない
3. agentの機械的確認をユーザー確認の代替として扱わない
4. 利用先を問わないpluginへ、この利用先固有の順序を書き込まない

追記する順序1〜3が条件1、順序3と2つ目の禁止が条件2と条件3、pluginを変更しないことが条件4を満たす。

#### 提案0へのフィードバック

**結果:** 受諾。

> ok

### 決定

`frontend/docs/ai_guideline/development_standard/testing.md` へ `## UI変更の動作確認` を新設し、動作確認の順序をagent先行として固定する。ユーザー確認gateは廃止せず、報告を受けたユーザーが進行を述べた時点で満たすものとする。報告には確認が及んでいない範囲も書く。

`tasklist.md` の動作確認taskの取消表現を、この読みへ合わせて置き換える。

pluginのskillは変更しない。agent先行という順序は、実行環境にブラウザ自動化があり、agentが実際に画面を触れる利用先でのみ成立する。利用先を問わないpluginへ書き込まない。

`tasklist-design.md` の「機械的確認はユーザー確認を代替しない」という規定は、今回の決定でも維持される。

**適用済み。** `doc-enricher`をこのdecision単位で別途起動していない。決定内容そのものがdocs修正であり、原因owner分類の段階で同じ因果分析を経ているためである。theme横断のreviewは`task-design-discussion.md`論点4が扱う。

---

## 論点5: 指定scriptを使わずPRを作成した

**ステータス:** 決定

**種別:** レビュー指摘

### イテレーション0: 原因ownerを決める

#### 提案0

原因を**repository知識**と分類し、`tumeda-dev-plugin-context.md` の branch / issue 契約へ「PR bodyへ`Closes #<issue番号>`を入れる」と追記する。

#### 提案0へのフィードバック

**結果:** 却下。

> は？ Aはスクリプト使わない理由にならないから。

提案0は「`Closes`が落ちたこと」への対処であり、「指定scriptを使わなかったこと」の説明にも防止にもなっていない。被害を分析して失敗そのものを分析していなかった。

### イテレーション1: 置換が成立する構造を原因として扱う

#### 提案1

原因を二層に分ける。

**直接原因（成果物固有）:** taskへ書かれたpathの実在を確認しなかった。一般化しない。

**構造的原因（skill）:** pluginの`task-design/templates/tasklist.md` の当該行を修正する。修正はplugin正本repositoryで行う。

```markdown
- [ ] pluginの`tasklist-executor` skill directory 配下の `scripts/github/create_or_get_pr.sh` を実行する
  - skill directory の絶対pathは skill 起動時に与えられる。利用先repositoryからの相対pathではない
  - このscriptは`gh pr create`のwrapperではない。branch名からissue番号を導き、repositoryが`feature-<issue番号>`契約を宣言していればPR bodyへ`Closes #<番号>`を入れる
  - 既存のopen PRがあれば新規作成せずそのURLを返す
```

`tasklist-executor/SKILL.md` へ、このscriptを同梱している旨を1行置く。

#### 提案背景

##### 事象

`tasklist.md` の完了後actionは `tasklist-executor/scripts/github/create_or_get_pr.sh` の使用を指定していた。実際には `gh pr list` で既存PRの不在を確認したうえで `gh pr create` を実行した。scriptの実在を確認していない。

結果、PRがissue #267へ紐づかなかった。issueは「評価タップ時に1回目空振りする」であり、本steeringが直接対応するものである。後から `Closes #267` を追記して修復した。

##### 指示側の欠陥

`tasklist-executor/SKILL.md` はこのscriptへ一度も言及していない。参照はtemplateの1行だけで、pathは利用先repositoryから解決できない相対pathである。所有者が自分の同梱物へ言及していないため、辿る導線がない。

加えて、当該行は手段と目的を一文へ同居させている。

> `create_or_get_pr.sh`を使い、既存PRがあれば再利用する

後半が受け入れ条件に読めるため、それを満たす別手段で置換できると判断させる。

##### 同型の欠陥を本session内で4回修正している

`task-design`の§4 trigger、NG集F1、`steering`のdiscussion trigger、`実装完了後review`。いずれも一文が二役を担い、片方がもう片方のgateまたは受け入れ条件に読めていた。今回は「適用範囲と実行者」ではなく「手段と目的」だが構造は同じである。

論点2で「同種の事例が一度しか観測されておらず一般則として書くには根拠が薄い」とした基準は、5回目の観測であるこれには当てはまらない。

##### 提案1が満たす必要のある条件

1. 名指しされた成果物へ、利用先repositoryから到達できる
2. 「同じ目的を果たす別手段」で満たせる文が残らない
3. scriptが単純なwrapperではないことが、実行前に分かる

skill directoryを起点とした説明が条件1、taskの本体を手段そのものにし目的を注記へ降ろすことが条件2、`wrapperではない`の記述が条件3を満たす。

#### 提案1へのフィードバック

**結果:** 受諾。

> ok。大した修正じゃないから、最後まで進めて

### 決定

具体ケースは修復済みとする。PR #272 のbodyへ `Closes #267` を追記し、`closingIssuesReferences` に #267 が入ることを確認した。`tasklist.md` の逸脱メモも事実へ訂正した。

一般則の側はplugin正本repositoryで扱う。`escalate-plugin-skill-fix` 経由で引き渡す。

- 正本側のsteering directory: `20260827-fix-substitutable-pr-script-task`
- 引き渡した提案: tasklist templateのPR作成taskが手段と目的を一文へ同居させ、指定scriptを別手段で置換できる形になっている問題を直す

議論の続きは正本repository側の記録が正である。本fileには続きを書き足さない。
