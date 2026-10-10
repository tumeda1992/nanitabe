# 議論記録（steering）

この steering の本体（backend の動作確認環境を ECS 上へ立てる）とは別に、作業の過程で気づいた事項を扱う。いずれもこの steering で発見したものであり、context が熱いうちに片付ける。

扱う対象は次の 5 件。

| # | 内容 | 出どころ |
| --- | --- | --- |
| 論点1 | test の migrate が `schema.rb` を sqlite 形式で上書きする | Phase 5 の後に `git status` で発見 |
| 論点2 | repository に無い migration が DB へ適用済みとして記録されている | 同上 |
| 論点3 | plugin template の状態遷移記法が text ブロック内の mermaid 記法になっている | design.md 初稿へのフィードバック |
| 論点4 | plan 検証入りの `apply_terraform.sh` を他の env へ広げるか | Phase 1 の apply が permission で止まった際の対処から |
| 論点5 | AWS resource を選ぶときの金額判断を document 化するか | 論点11（alarm の採否）で材料が揃った |

## 論点1: test 環境の migrate が `schema.rb` を sqlite 形式で上書きする

**ステータス:** 決定

**種別:** 既存の不具合

### イテレーション0: schema.rb が書き換わらないようにする

#### 提案0

`backend/config/environments/test.rb` へ次の 1 行を足す。

```ruby
config.active_record.dump_schema_after_migration = false
```

`backend/config/environments/production.rb:92` に同じ設定があり、その前例へ揃える形になる。

**なぜこれで直るか**

Rails の `db:migrate` は、実行後に接続先 DB の構造を `schema.rb` へ dump する。開発用 `backend/entrypoint.sh` は `./bin/rails db:migrate RAILS_ENV=test` を実行しており、`database.yml` の test は sqlite3 である。そのため container を起動するたびに、sqlite の構造から `schema.rb` が再生成される。

MySQL 固有の `charset: "utf8mb4"` と `collation: "utf8mb4_0900_ai_ci"` は sqlite に存在しないため、dump から落ちる。実際に今回、14 箇所すべてから消えた状態の `schema.rb` が作業ツリーへ現れた。

`dump_schema_after_migration = false` を test へ設定すると、test 環境の migrate が `schema.rb` を書き換えなくなる。development（MySQL）での migrate は従来どおり dump するため、`schema.rb` は MySQL の構造を保ち続ける。

**この不具合が持つ危険**

`schema.rb` は version 管理下にある。container を起動しただけで作業ツリーが汚れ、気づかずに `git add .` すると **charset が落ちた `schema.rb` が commit される**。その状態で誰かが `db:schema:load` を実行すると、MySQL の charset 指定が無いテーブルが作られる。

今回は `git status` をたまたま見て気づいた。次も気づける保証はない。

#### 提案背景

Phase 5 の後に commit 対象を確認したところ、`backend/db/schema.rb` が変更されていた。変更は 2 種類あり、片方（charset の消失）が本論点、もう片方（version の進行）が論点2 にあたる。

対策として次の 3 つを検討した。

- **`db:migrate RAILS_ENV=test` を `db:test:prepare` へ置き換える**: `db:test:prepare` は `schema.rb` から test DB を作るため、`schema.rb` を書き換えない。ただし `schema.rb` が古い状態だと test DB も古くなる。現在まさに `schema.rb` の version が DB より古いため（論点2）、この置き換えは論点2 の解決を前提にする。
- **entrypoint から test の migrate を消す**: test DB の準備が誰の責務でもなくなる。rspec 実行前に手動で用意することになり、開発体験が落ちる。
- **`dump_schema_after_migration = false` を test へ設定する**: migrate 自体は従来どおり動き、`schema.rb` だけを守る。変更は 1 行で、production に前例がある。

3 つ目を採る。1 つ目は論点2 と結合しており、単独では適用できない。

#### 提案0へのフィードバック

**結果:** 受諾。

> 論点1について合意。

### 決定

`backend/config/environments/test.rb` へ `config.active_record.dump_schema_after_migration = false` を足す。`production.rb:92` の前例へ揃える。

これにより、開発用 `entrypoint.sh` の `./bin/rails db:migrate RAILS_ENV=test` が `schema.rb` を書き換えなくなる。development（MySQL）での migrate は従来どおり dump するため、`schema.rb` は MySQL の構造を保つ。

## 論点2: repository に無い migration が DB へ適用済みとして記録されている

**ステータス:** 決定

**種別:** 既存の不具合

### イテレーション0: 何が起きたかを特定する

#### 提案0

原因に心当たりがあるかを確認したい。現時点で分かっている事実を並べる。

**確認した事実**

- 開発 DB（MySQL）と test DB（sqlite）の両方で、`schema_migrations` の最大 version が `20260830110413` である。
- `backend/db/migrate/` にある migration file の最大は `20260425122541` であり、`20260830110413` に対応する file は存在しない。
- `git log --all -S "20260830110413"` で全 branch の全履歴を検索したが、この文字列を含む commit は無い（ヒットするのは今回の steering 記録のみ）。
- `git log --all --diff-filter=D -- 'backend/db/migrate/20260830*'` でも削除履歴は見つからない。
- `main` の `schema.rb` は version `2026_04_25_122541` であり、この drift は今回の作業が作ったものではない。

**つまり**

migration file は repository のどこにも存在したことがなく、DB にだけ「適用済み」の記録がある。

考えられる経路は次のいずれかになる。

1. migration file を作って実行し、commit せずに file を削除した
2. `schema_migrations` へ手作業で INSERT した
3. 別の repository または別の環境から同じ DB へ適用された

**なぜ特定したいか**

対処が経路によって変わる。1 なら、その migration が実際に何をしたか（テーブルやカラムが増えているか）を確認し、必要なら migration file を復元するか、記録だけを削除する。2 なら記録を削除すればよい。3 なら、その環境との関係を整理する必要がある。

記録だけを消すと、もし実際にスキーマ変更が行われていた場合、その変更が `schema.rb` に反映されないまま残る。逆に放置すると、`schema.rb` と DB の version が食い違ったままになり、論点1 で検討した `db:test:prepare` への移行もできない。

`20260830` は 2026 年 8 月 30 日にあたる。同日付の steering として `20260830-consolidate-frontend-build-scripts` があるが、これは frontend の build script を扱っており DB とは無関係である。

#### 提案0へのフィードバック

**結果:** 心当たりが示され、そこから原因を特定できた。

> 論点2はpendingになっている feature-71 の影響かな

### イテレーション1: 原因の特定と、この状態が持つ意味

#### 提案1

**特定した原因**

未 merge の `feature-71` branch に、該当する migration が 2 つ存在する。

```text
backend/db/migrate/20260829132653_create_postponed_meals.rb
backend/db/migrate/20260830110413_add_comment_to_postponed_meals.rb
```

`feature-71` の `schema.rb` も version `2026_08_30_110413` になっている。

提案0で挙げた 3 つの経路のうち、1（migration を作って実行したが未 commit）でも 2（手作業の INSERT）でもなく、**branch 上には正しく commit されているが、その branch が未 merge のまま開発 DB へ適用されている**状態だった。開発 DB を全員で共有しているため、branch 作業中の migration がそのまま共有 DB へ反映される。

**実態の確認**

共有している開発 DB に `postponed_meals` テーブルが実在する。

```text
id, user_id, dish_id, meal_type, created_at, updated_at, comment
```

migration の内容（`user`/`dish` への references、`meal_type`、`comment` カラムの追加）と一致する。つまりスキーマ変更は実際に行われている。

**この状態が持つ意味**

記録だけを削除する対処は取れない。テーブルが実在するため、記録を消すと `schema_migrations` とスキーマの実態が食い違う。

また、この drift は `feature-71` が merge されるまで続く。その間、`main` 由来のコードは `postponed_meals` を知らないまま、DB にはそのテーブルがある状態になる。

今回作った review 環境にも影響する。`review` branch へ `main` 由来のコードを載せて起動すると、`rails db:migrate` は `20260830110413` を適用済みと判断して何もしない。**DB が先行し、コードが追いついていない状態で動く。** 今回の起動では no-op で済んだが、それはこの drift が「DB 側にテーブルが余分にある」という方向だったためである。逆方向（コードが DB より新しい）であれば、未適用の migration が共有 DB へ適用される。

**提案する対処**

この drift 自体は解消しない。`feature-71` が merge されれば自然に解消する種類のものであり、今この steering で触ると `feature-71` の作業と競合する。

代わりに、論点1 で検討した `db:test:prepare` への移行を見送る理由として記録する。提案0 の検討で「`schema.rb` が古い状態だと test DB も古くなるため、論点2 の解決が前提になる」と書いたが、その前提は `feature-71` の merge によって満たされる。今は `dump_schema_after_migration = false` の対処だけを入れる。

あわせて、開発 DB を共有している構成では branch 作業中の migration が共有 DB へ反映されることを、既知の性質として記録する。これは review 環境が開発 DB を共有するという今回の決定（task-design-discussion の論点2）とも地続きであり、同じ性質から生じている。

#### 提案1へのフィードバック

**結果:** 原因の特定と、drift を解消しない方針を受諾。

### 決定

`schema_migrations` の `20260830110413` は、未 merge の `feature-71` branch にある `20260830110413_add_comment_to_postponed_meals.rb` が開発 DB へ適用されたものである。同 branch の `20260829132653_create_postponed_meals.rb` も適用されており、共有 DB に `postponed_meals` テーブルが実在する（列は `id`、`user_id`、`dish_id`、`meal_type`、`created_at`、`updated_at`、`comment`）。

この drift はこの steering では解消しない。

- 記録だけを削除する対処は取れない。テーブルが実在するため、消すと `schema_migrations` とスキーマの実態が食い違う。
- `feature-71` が merge されれば自然に解消する。今ここで触ると `feature-71` の作業と競合する。

**記録しておく性質**

開発 DB を共有している構成では、branch 作業中の migration がそのまま共有 DB へ反映される。その branch が未 merge の間、`main` 由来のコードは知らないテーブルが DB に存在する状態になる。

これは review 環境にも及ぶ。`review` branch へ `main` 由来のコードを載せて起動すると、`rails db:migrate` はその version を適用済みと判断して何もしない。DB が先行し、コードが追いついていない状態で動く。今回の起動で no-op だったのは、drift が「DB 側にテーブルが余分にある」方向だったためである。逆方向（コードが DB より新しい）なら、未適用の migration が共有 DB へ適用される。これは task-design-discussion の論点2 で受け入れたリスクそのものである。

論点1 の検討で `db:test:prepare` への移行を見送ったが、その理由（`schema.rb` が DB より古い状態では test DB も古くなる）は `feature-71` の merge によって解消する。移行を検討するならその後になる。

## 論点3: plugin template の状態遷移記法

**ステータス:** plugin repository で対応済み

**種別:** plugin skill への修正提案

この提案は plugin repository で扱う。`escalate-plugin-skill-fix` の契約により、議論の続きと合意内容は plugin repository 側の記録が正である。

- 作業した steering directory の basename: `20260919-add-confidentiality-standard-and-fix-state-notation`
- 引き渡した提案の要旨: `task-design` の workflow template が ```text 内へ mermaid 風の記法を規定しており、どちらの媒体でも読めない

## 論点4: plan 検証入りの apply script を他の env へ広げるか

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0: prod へ広げるかを決める

#### 提案0

**推奨:** 広げない。review 環境に限定したままにする。

**現状**

`infrastructure/terraform/envs/review/apply_terraform.sh` は、plan の実行と destroy 判定を含む。

```sh
terraform plan -out=tfplan.review
destroy_count=$(terraform show -json tfplan.review | python3 -c "...")
if [ "$destroy_count" -ne 0 ]; then exit 1; fi
terraform apply tfplan.review
```

prod 側の `apply_terraform.sh` は `terraform apply` を直接実行する形のままである。

**広げない理由**

この形を review 環境で採ったのは、**agent が permission を持って apply を実行するため**である。harness の permission を script 単位で与えると、design が定めた「apply の前に plan で差分を確認する」契約が人の目視に依存したままになり、飛ばされうる。契約を script 自身へ埋め込むことで、permission を与えても契約が守られる。

prod の apply を agent が実行する想定は現在ない。人が実行する場合、`terraform apply` の対話確認で差分を目視できるため、script 側の判定が無くても差分を見ずに適用することにはならない。

つまり、この script が解いている問題が prod には存在しない。

**広げた場合に増えるもの**

- `python3` への依存。現在の prod の script は `terraform` と shell の組み込みコマンドだけで完結している。
- plan が毎回走るため実行時間が伸びる。
- 既存の運用手順（`./apply_terraform.sh` を実行する）の挙動が変わる。対話確認が出なくなり、plan の内容を見る機会が減る。最後の点は、目視確認を前提にしている prod ではむしろ後退になる。

**広げる論拠と、それを採らない理由**

destroy を含む差分に対して人が確認を読み飛ばす可能性は prod でも同じであり、むしろ prod のほうが影響が大きい。これは広げる論拠になる。

ただし prod の apply は頻度が低く、実行者が内容を把握している場面に限られる。自動化されていない操作へ機械的な gate を足すより、実行者が差分を読む運用を保つほうが素直である。prod の apply を agent が実行する要求が出た時点で、改めて検討すればよい。

#### 提案背景

Phase 1 で `terraform apply` が harness の permission classifier に block され、その対処として script へ契約を埋め込んだ。実装レビューの論点1 で決定した際、「一般運用するかどうかは別」としてこの論点を保留にしていた。

review 環境でこの script を実際に 5 回以上使った。plan が毎回走ることによる待ち時間は数秒から十数秒で、体感として問題にならなかった。destroy 判定の誤検知も発生していない。`evaluation_periods` の変更のような既存 resource の更新でも、`0 added / 1 changed / 0 destroyed` として正しく通過している。

つまり「review 環境で使ってみた結果、広げることの障害は無い」という状態になった。障害が無いことと、広げるべきことは別である。

#### 提案0へのフィードバック

**結果:** 受諾。現時点では広げない。

> 一旦広げなくていいよ

### 決定

plan の実行と destroy 判定を含む形は、`infrastructure/terraform/envs/review/apply_terraform.sh` に限定する。prod 側の `apply_terraform.sh` は `terraform apply` を直接実行する現在の形のままとする。

**この判断の根拠**

script へ契約を埋め込んだのは、agent が harness の permission を持って apply を実行するためである。permission を script 単位で与えると、「apply の前に plan で差分を確認する」契約が人の目視に依存したままになり飛ばされうる。契約を script 自身へ入れることで、permission を与えても守られる。

prod の apply を agent が実行する想定は現時点で無い。人が実行する場合は `terraform apply` の対話確認で差分を目視できるため、script 側の判定が無くても差分を見ずに適用することにはならない。つまりこの script が解いている問題が prod には存在しない。

広げた場合、plan file を渡す形は確認プロンプトを出さないため、**差分を読む機会がむしろ減る**。目視を前提にしている prod では後退になる。あわせて `python3` への依存が増え、既存の運用手順の挙動も変わる。

**採らなかった論拠**

destroy を含む差分に対して人が確認を読み飛ばす可能性は prod でも同じであり、むしろ影響は大きい。これは広げる論拠になる。ただし prod の apply は頻度が低く、実行者が内容を把握している場面に限られる。機械的な gate を足すより、実行者が差分を読む運用を保つほうが素直だと判断した。

**再検討の条件**

prod の apply を agent が実行する要求が出た時点で、改めて検討する。その時点では review と同じ問題（permission を与えると目視確認が飛ばされうる）が prod にも発生するため、判断の前提が変わる。

**review 環境での実績**

この script を 5 回以上使用した。plan が毎回走ることによる待ち時間は数秒から十数秒で、体感として問題にならなかった。destroy 判定の誤検知も発生していない。`evaluation_periods` の変更のような既存 resource の更新でも `0 added / 1 changed / 0 destroyed` として正しく通過した。

障害が無いことと、広げるべきことは別である。実績は「広げても壊れない」ことを示すが、「広げる理由がある」ことは示さない。

## 論点5: AWS resource を選ぶときの金額判断を document 化するか

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0: document 化の要否と置き場所を決める

#### 提案0

**推奨:** `infrastructure/README.md` の「構成上の前提」へ 1 項目として足す。独立した file は作らない。

**書く内容**

```markdown
- **課金の判断**: resource を構成へ含めるかを金額で判断するとき、次を分けて考える。
  - 時間課金（ALB、RDS、NAT Gateway、Elastic IP）は、存在するだけで課金が積み上がる。使っていない時間も払う。
  - 保存・件数課金（ECR の image、CloudWatch Logs、alarm）は、量に比例する。量を抑える設定（lifecycle policy、retention）で管理できる。

  「常時課金の resource を含めない」という形の基準は、少額で損失を防ぐ resource まで機械的に退ける。
  防ぐ対象の損失と、防ぐための固定費を並べて比べる。例: 止め忘れた Fargate task は 3 日で $0.86、
  1 か月で $8.6 になる。これを検知する alarm は月 $0.10 であり、年 1 回から 2 回の止め忘れで釣り合う。

  同じ目的を達成する手段が複数あるとき、額が桁で違うことがある。止め忘れの検知では、
  Container Insights（月 $3 から $6）と標準 metric + alarm（月 $0.10）が同じ判定を実現する。
  手段を 1 つ思いついた時点で決めず、他の手段の額も見る。
```

**独立した file を作らない理由**

`doc-enricher` は新規 docs の作成を禁じており、既存 README への追記を基本としている。また `infrastructure/README.md` の「構成上の前提」は、既に「新しい resource を足すときに成立している前提」を列挙する節になっており、この内容はその文脈に収まる。

読者も一致する。この判断が必要になるのは AWS resource を足すときであり、その人は `infrastructure/README.md` を読む。

**適用範囲**

この repository の AWS resource 全般とする。review 環境に限定しない。判断の形（時間課金と保存・件数課金の区別、損益分岐の計算、手段の額の比較）は環境に依存しない。

#### 提案背景

論点11（完成をどう検証し、どのリスクを受け入れるか）で、月 $0.10 の CloudWatch alarm を「時間課金の resource を含めない」という要件だけを根拠に退けた。ユーザーから「その料金なら CloudWatch alarm 入れていいよ。失敗していたときのほうが金かかるんだから」と指摘され、費用対効果を見ていなかったことが判明した。

その後 alarm の metric を選ぶ際にも、Container Insights（月 $3 から $6）と標準 metric + alarm（月 $0.10）が同じ判定を実現することが分かり、手段によって額が桁で違う場面があることも確認できた。

要件の表現自体は「停止中に発生する課金を image と log の保存料および alarm に限り、合計で月 $1 を超えない」へ改めた。ただしこれは今回の design に閉じた表現であり、次に AWS resource を足す人が同じ判断をやり直すことになる。

この steering で materialize した材料は次の 3 つである。

- 時間課金と保存・件数課金を分けて扱う必要がある
- 損益分岐を計算する。防ぐ対象の損失と固定費を並べる
- 同じ目的の手段が複数あり、額が桁で違うことがある

これらは環境にも repository にも依存しない判断の形であり、document へ残す価値がある。

#### 提案0へのフィードバック

**結果:** 独立した file を作らないという提案が覆された。1 file を作る。

> 全然1ファイル作っていいほど。総論自体もこれから育つし、各論もサービスごとで細かくなっていくだろうし、どの場合に適用okで、みたいな場合分けもたくさんでてくるはず

提案0は「今回書ける分量」を基準に置き場所を決めていた。総論が育ち、サービスごとの各論が増え、適用可否の場合分けが増えることを見ていなかった。README の 1 項目では、増えた時点で分割し直すことになる。

### イテレーション1: file の構成を決める

#### 提案1

`infrastructure/cost_judgment.md` を新規作成する。`infrastructure/` 直下に置き、`infrastructure/docs/` のような階層は作らない。1 file のために階層を掘ると、読み手に「ここか、さらに下か」を毎回判断させるためである。

見出し構成を次のとおりにする。

```text
# 費用の判断
├── 何を判断する document か（対象と対象外）
├── 課金モデルを分けて考える
│   ├── 時間課金 — 存在するだけで積み上がる
│   └── 保存・件数課金 — 量に比例し、設定で抑えられる
├── 判断の手順
│   ├── 1. 防ぐ対象の損失を見積もる
│   ├── 2. 手段を複数出す（1 つ思いついた時点で決めない）
│   └── 3. 損益分岐で比べる
├── サービス別の要点
│   ├── ECS / Fargate
│   ├── CloudWatch
│   ├── ECR
│   ├── API Gateway
│   └── Secrets Manager / SSM Parameter Store
├── やってしまいがちな失敗
└── 参照
```

「課金モデル」へ新しい型を足す、「サービス別の要点」へ触ったサービスを足す、「やってしまいがちな失敗」へ具体例を足す、という形で育つ構造にする。

初版で書くのはこの steering で得た材料に限る。空の節は作らない。

#### 提案背景

feedback により、この document が育つことを前提にした構成が必要になった。育つ方向は 3 つある。総論（判断の形）、各論（サービスごとの課金モデル）、場合分け（どの場合に適用してよいか）である。

「サービス別の要点」を独立した節にすることで、新しいサービスを触った人がそこへ足せる。「やってしまいがちな失敗」を節にすることで、判断を誤った事例が具体例として蓄積する。この 2 つが各論と場合分けの受け皿になる。

#### 提案1へのフィードバック

**結果:** 受諾。

> ok

### 決定

`infrastructure/cost_judgment.md` を新規作成した。上記の見出し構成で、この steering で得た材料を初版として書いた。

**初版に含めた内容**

- 課金モデルを時間課金と保存・件数課金に分け、それぞれの性質と判断への影響を書いた。
- 判断の手順を 3 段（損失の見積もり、手段の複数出し、損益分岐）にした。それぞれへ今回の実例（Fargate の止め忘れ、Container Insights と標準 metric の比較、alarm の損益分岐）を添えた。
- サービス別の要点として ECS / Fargate、CloudWatch、ECR、API Gateway、Secrets Manager / SSM Parameter Store を書いた。いずれもこの steering で実際に判断材料にしたもの。
- やってしまいがちな失敗を 2 つ書いた。どちらもこの steering で実際に起きたものである。

**README との関係**

`infrastructure/README.md` の「停止中にかかる費用」は、review 環境が実際に何を含み何を含めていないかという事実を持つ。`cost_judgment.md` は、なぜそう判断するかという基準を持つ。役割が違うため両方を残し、README から `cost_judgment.md` を参照する。

あわせて README の「構成上の前提」へも 1 行足した。新しい resource を足す人の動線になる。

## 論点6: 機密情報を document へ書かないための標準が無い

**ステータス:** plugin repository で対応済み

**種別:** plugin docs への修正提案

この提案は plugin repository で扱う。`escalate-plugin-skill-fix` の契約により、議論の続きと合意内容は plugin repository 側の記録が正である。

- 作業した steering directory の basename: `20260919-add-confidentiality-standard-and-fix-state-notation`
- 引き渡した提案の要旨: `document-review` が機密情報の観点を持たないため、md を emit しても機密情報の混入が検知されない


## 論点7: 本番 backend の管理画面 URL が公開されている

**ステータス:** 決定済み

**種別:** 機密情報の混入

### イテレーション0: 除去するかと、その範囲を決める

#### 提案0

**推奨:** a。document と application code の両方を直す。

- **a. document と code の両方を直す**
  - document 側は該当行から URL を落とす。code 側は URL を環境変数へ移す。
  - `confidentiality.md` の判定では、document も code も同じ公開範囲に置かれる。document だけ直しても、code に実値が残れば読んだ人ができることは変わらない。
  - code 側の変更は、値を build 時の環境変数から読む形にする。frontend の build 設定を確認してから具体を決める。
- **b. document だけ直す**
  - code は管理画面へのリンクという機能を持つため、URL が必要である。
  - ただし URL が必要なことと、実値を repository へ置くことは別である。環境変数から読めば機能は保たれる。この案は「必要だから置く」で止まっており、代替を検討していない。
- **c. 何もしない**
  - 既に公開されており、いま除去しても過去の commit には残る。
  - ただし利用者は過去に同種の事象で「最新のスナップショットに情報が残っていなければ感知されない」という判断を示しており、最新から消すこと自体に意味を認めている。この案はその判断と整合しない。

#### 提案背景

**何が公開されているか**

本番 backend の管理画面 URL が、document 1 箇所と application code 2 箇所に実値で書かれている。

- document: 2026 年 3 月の steering の `tasklist.md`。`main` に取り込み済み
- application code: frontend の component 1 箇所、native app 1 箇所。いずれも `main` にある

**判定**

`confidentiality.md` の判定を当てる。

第 1 段。この記述が公開されたとき、それを読んだ人は何ができるようになるか。**管理画面へ到達できる。** host 名と path が揃っており、経路が完成している。第 2 段へ進む。

第 2 段。URL は対象を一意に指す識別子である。その document が作る対象であっても実値を書かず、変数または placeholder で参照する。

**今回の作業で除去した 40 箇所との違い**

今回の steering の domain 実値は未 push であり、履歴へ載せずに除去できた。この件は `main` に取り込み済みであり、過去の commit からは消えない。除去できるのは最新のスナップショットだけである。

**code を対象に含める理由**

`confidentiality.md` は document の標準であり、code を対象としていない。ただし判定の起点は「この記述が公開されたとき、それを読んだ人は何ができるようになるか」であり、この問いは記述が置かれた file の種類を区別しない。同じ public repository にある以上、document から消して code に残しても、読んだ人ができることは変わらない。

#### 提案0へのフィードバック

**結果:** 合意。a を採る。

### イテレーション1: 対象を訂正し、実装方法を決める

#### 提案1

**推奨:** a。backend の origin を解決する既存ロジックを関数として切り出し、component から使う。

**対象の訂正**

提案0 は対象を「document 1 箇所と application code 2 箇所」としたが、調査の結果 code は 1 箇所だった。

`native/App.tsx` が持つのは本番 backend の管理画面 URL ではなく、**frontend 本番の URL** である。frontend 本番は公開されている service であり、第 1 段の問いに対して「読んだ人が新しくできるようになること」が無い。`confidentiality.md` の「該当しない例」が挙げる「公開 API の endpoint 名: すでに公開されている」と同じ形で落ちる。

したがって対象は次の 2 箇所になる。

- document: 2026 年 3 月の steering の `tasklist.md`。`main` に取り込み済み
- application code: frontend の component 1 箇所

**実装方法**

frontend は backend の origin を既に環境変数で持っている。`NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN` であり、build 時に CodeBuild の環境変数から注入され、terraform が値を管理している。**新しい環境変数は要らない。**

ただし `buildApolloClient.ts` は、この値をそのまま使うのではなく development との分岐を持っている。

- 本番など development 以外: `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN`
- development の server side: `http://nanitabe_back:18101`
- development の client side: `http://localhost:18101`

管理画面のリンクも同じ分岐が要る。development で本番の管理画面へ飛ぶのは意図と違う。

- **a. origin 解決を関数として切り出す**
  - `buildApolloClient.ts` の `generateURL` 内にある origin 解決の IIFE を、origin を返す関数として切り出す。`generateURL` はその関数へ `/graphql` を足す形にし、component は同じ関数へ `/admin/...` の path を足す。
  - 分岐が 1 箇所に残り、環境ごとの対応が 2 箇所へ分かれない。
  - 既存 file への変更を伴うが、振る舞いは変わらない。
- **b. component で環境変数を直接読む**
  - `process.env.NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN` を component から読み、path を足す。
  - 変更が component だけで閉じる。
  - ただし development では値が未定義であり、リンクが `undefined/admin/...` になる。分岐を component 側へ書くと、同じ分岐が 2 箇所に並ぶ。
- **c. 管理画面用の環境変数を新設する**
  - `NEXT_PUBLIC_ADMIN_ORIGIN` のような変数を足し、terraform と buildspec へ追加する。
  - backend の origin と同じ値を二重に持つことになる。片方だけ変わると壊れる。

#### 提案背景

提案0 の decision は「code 側の具体的な実装は、frontend と native app の既存の環境変数の扱いを確認してから決める」としていた。確認した結果、次の二点が判明した。

1. `native/App.tsx` は対象外である。持っているのは frontend 本番の URL であり、判定の第 1 段で落ちる。
2. backend の origin は既に環境変数として存在し、build pipeline と terraform が値を運んでいる。新設は不要である。

2 点目により、選択は「どの変数を足すか」ではなく「既にある origin 解決をどう共有するか」になった。

#### 提案1へのフィードバック

**結果:** 合意。a を採る。

### 決定

本番 backend の管理画面 URL の実値を、次の 2 箇所から除去する。

- document: 2026 年 3 月の steering の `tasklist.md`。該当行から URL を落とす
- application code: frontend の component 1 箇所

`native/App.tsx` は対象に含めない。持っているのは frontend 本番の URL であり、公開されている service を指すため、第 1 段の問い「読んだ人は何ができるようになるか」に対して新しくできるようになることが無い。

code 側は、`buildApolloClient.ts` の `generateURL` 内にある origin 解決の IIFE を、origin を返す関数として切り出す。`generateURL` はその関数へ `/graphql` を足す形にし、component は同じ関数へ管理画面の path を足す。環境ごとの分岐が 1 箇所に残り、development で本番の管理画面へ飛ぶことも防げる。

新しい環境変数は作らない。backend の origin は `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN` として既に存在し、build 時に CodeBuild から注入され、terraform が値を管理している。管理画面用に別の変数を足すと、同じ値を二重に持つことになる。


## 論点8: 既存 DB の防御構成を、設計根拠として残すか

**ステータス:** 決定済み

**種別:** 機密情報の混入

### イテレーション0: 残すかどうかを決める

#### 提案0

**推奨:** a。除去する。

- **a. 除去する**
  - 既存 DB の防御構成に関する記述を、`design.md`、`task-design-discussion.md`、`implementation_review.md` から落とす。
  - `confidentiality.md` の第 2 段は「構成の性質は、その document が作る対象なら書く。既存環境のものは書かない」と定める。DB は既存環境であり、今回の design が作る対象ではない。
  - 設計根拠としては「起動のたびに接続元を登録する必要がない」という結論が残る。なぜ不要かの理由は落ちるが、結論だけで設計は成立する。
- **b. 残す**
  - 前回の判断どおり、設計判断の根拠として保つ。
  - ただし前回の判断は、機密情報の標準が無い時点で「根拠として必要」という理由だけで行われた。標準ができた今、同じ理由が判定を通るかを問い直す必要がある。
- **c. 理由を抽象化して残す**
  - 「DB 側の設定により、接続元の登録は起動のたびに不要である」という形にし、防御構成そのものを書かない。
  - 結論と、結論が DB 側の設定に依存することの両方が残る。
  - ただし「DB 側の設定により」が何を指すかは読み手に伝わらない。後から「本当に不要か」を検証する人は、結局 DB 側を見に行く。それは a と変わらない。

#### 提案背景

**何が書かれているか**

既存 DB の防御構成に関する記述が 3 file にある。いずれも `feature-278` へ push 済みで、`main` には未取り込みである。

**前回の判断**

`implementation_review.md` に前回の判断が記録されている。具体的な開放範囲は落とし、「接続元を IP で絞っていない」という事実は設計判断の根拠として残す、という線を引いた。

この判断は、機密情報の標準が存在しない時点で行われた。根拠として必要かどうかだけを見ており、公開されたときに何ができるようになるかを問うていない。

**標準を当てた結果**

第 1 段。この記述が公開されたとき、読んだ人は何ができるようになるか。DB の所在は書かれていないため、単独では到達できない。ただし防御の厚みが分かる。`confidentiality.md` の第 1 段は「単独では無害に見える記述でも、既知の情報と組み合わさって到達経路が完成するなら、できるようになることがある」と定めており、public repository の他の成果物と合わせた判定が要る。

第 2 段。security group の設定は構成の性質である。DB は既存環境であり、この design が作る対象ではない。したがって書かない。

**標準の締めとの照合**

`confidentiality.md` は「この標準は、構成について書くこと自体を禁じるものではない。禁じるのは、既存環境の構成の性質と、実値で書かれた識別子である。設計文書が自分の作る対象を説明できなくなっているなら、判定の当て方を間違えている」と締めている。

今回除去する対象は既存 DB の説明であり、この design が作る対象ではない。除去しても、この design が作る security group（task の port を開ける設定と、その対策）は残る。設計文書が自分の作る対象を説明できなくなることはない。

#### 提案0へのフィードバック

**結果:** 合意。a を採る。

### 決定

既存 DB の防御構成に関する記述を、`design.md`、`task-design-discussion.md`、`implementation_review.md` から除去する。

設計根拠としては「起動のたびに接続元を登録する必要がない」という結論を残す。なぜ不要かの理由は落ちるが、結論だけで設計は成立する。

`implementation_review.md` は前回の判断の記録であり、判断の経緯そのものは消さない。機密にあたる記述だけを落とし、この論点で判断が変わったことを注記する。

**前回の判断が覆った理由**

前回は機密情報の標準が存在しない時点で、「設計判断の根拠として必要か」だけを見て残すと決めた。標準ができたことで、判定が「公開されたとき読んだ人は何ができるようになるか」へ変わり、第 2 段の「既存環境の構成の性質は書かない」に当たった。

判断が変わったのは、前回の判断が誤っていたからではなく、判定の基準が増えたからである。


## 論点9: 既存 AWS 構成の実測結果をどこまで残すか

**ステータス:** 決定済み

**種別:** 機密情報の混入

### イテレーション0: 残す範囲を決める

#### 提案0

**推奨:** a。識別子の実値を落とし、設計判断に効く性質だけを残す。

- **a. 識別子の実値を落とし、性質だけ残す**
  - VPC の ID と CIDR、別プロジェクトの ECS cluster 名、ECR repository 名を落とす。
  - 「VPC は default の 1 つだけで、subnet は 3 つとも public。private subnet と NAT Gateway は存在しない」「backend 用の cluster は無い」「backend 用の ECR repository は無い」という性質は残す。
  - 設計判断に効いたのは性質であって、識別子ではない。private subnet が無いという性質が Fargate task を public subnet へ置く判断を規定した。VPC の ID はその判断に関与していない。
- **b. 全部残す**
  - 実測結果をそのまま置く。再調査のコストが下がる。
  - ただし `confidentiality.md` の第 2 段は「識別子はその document が作る対象であっても実値を書かない」と定める。再調査のコストは、実値を書く理由として扱われていない。
- **c. ブロックごと落とす**
  - 「AWS account の既存構成」の項目自体を削る。
  - ただし設計判断の根拠が失われる。なぜ public subnet へ置いたのか、なぜ cluster を新規に作ったのかが辿れなくなる。

#### 提案背景

**何が書かれているか**

`design.md` の付録「AWS account の既存構成（AWS CLI で実測）」に、次が実値で書かれている。

- VPC の ID と CIDR
- subnet の AZ と public 属性
- 別プロジェクト用の ECS cluster 名
- ECR repository 名
- hosted zone の数

**判定**

第 1 段。公開されたとき読んだ人は何ができるようになるか。AWS account の構成が分かる。account ID が無ければ直接操作はできないが、resource の命名規則と、どの service を使っているかが判明する。別プロジェクトの cluster 名は、同じ account に別のプロジェクトが存在することを明かす。第 2 段へ進む。

第 2 段。VPC の ID、cluster 名、ECR repository 名は、対象を一意に指す識別子である。`confidentiality.md` が第 2 段の例として挙げる「resource 名」にそのまま当たる。その document が作る対象であっても実値を書かない。

subnet が 3 つとも public であること、private subnet と NAT Gateway が無いことは構成の性質にあたる。既存環境のものであるため、第 2 段の規則では書かない側になる。

ただしこの性質は、今回の design が「Fargate task を public subnet へ public IP 付きで置く」と決めた根拠そのものである。落とすと、なぜその形を選んだかが辿れなくなる。論点8 で除去した DB の防御構成とは、設計への効き方が違う。DB の防御構成は「接続元の登録が不要」という結論を残せば設計が成立したが、network の構成は結論だけでは「なぜ private subnet を使わないのか」に答えられない。

**この違いをどう扱うか**

提案 a は、識別子（第 2 段で落ちる）と性質（設計根拠として必要）を分けて扱う。性質のうち残すのは、今回の design の判断を規定したものに限る。別プロジェクトの存在や、backend と無関係な resource の一覧は、判断を規定していないため落とす。

#### 提案0へのフィードバック

**結果:** 合意。a を採る。

### 決定

`design.md` の「AWS account の既存構成」から、識別子の実値を落とし、設計判断を規定した性質だけを残す。

落とすもの。

- VPC の ID と CIDR
- subnet の AZ 名
- 別プロジェクト用の ECS cluster 名
- ECR repository 名

残すもの。

- VPC が default の 1 つだけであること、subnet が 3 つとも public であること、private subnet と NAT Gateway が存在しないこと。これが Fargate task を public subnet へ public IP 付きで置く判断を規定した
- backend 用の ECS cluster と ECR repository が存在しないこと。新規に作る判断の前提になる
- Route53 hosted zone が 1 つだけであること

別プロジェクトの存在や、backend と無関係な resource の一覧は落とす。今回の判断を規定していないためである。

論点8 との違いを記録する。論点8 で除去した DB の防御構成は、「接続元の登録が不要」という結論だけで設計が成立した。network の構成は結論だけでは「なぜ private subnet を使わないのか」に答えられないため、性質を残す。第 2 段の規則は既存環境の構成の性質を書かないと定めるが、その性質が今回の design の判断を規定している場合は、識別子を落としたうえで性質を残す。


## 論点10: 参照元 private repository の名前をマスクするか

**ステータス:** 決定済み

**種別:** 機密情報の混入

### イテレーション0: マスクするかを決める

#### 提案0

**推奨:** a。マスクする。

- **a. マスクする**
  - 2026 年 7 月の steering（skill を shared plugin へ移行したもの）にある参照元 repository 名 7 箇所を、役割を示す語へ置き換える。
  - private にしているということは、公開したくないという意図がある。その名前が public repository へ出るのは意図に反する。
  - 文脈は保たれる。どの repository から移植したかという具体名は、「先行して同じ移行を行った repository」で置き換えられる。判断の根拠になっていたのは「既に同じ移行を済ませた前例がある」ことであり、その repository の名前ではない。
- **b. 残す**
  - repository 名だけでは access できない。GitHub 上では private repository は 404 を返し、存在の有無すら確認できない。
  - ただし `confidentiality.md` の第 1 段は判定を攻撃に限定していない。「本人への害」も判定対象に含む。private にした意図が損なわれること自体が判定の対象になる。
- **c. 引用以外だけマスクする**
  - `design.md` 冒頭の依頼内容は原文であり、改変しない。それ以外の 6 箇所をマスクする。
  - ただし原文に残れば公開される内容は変わらない。引用を保つことと、公開しない意図を守ることが両立しない。

#### 提案背景

**何が書かれているか**

2026 年 7 月の steering に、参照元 repository の名前が 7 箇所ある。うち 1 箇所は `design.md` 冒頭の依頼内容で、local path を含む形で書かれている。この steering は `main` に取り込み済みである。

**判定**

第 1 段。公開されたとき読んだ人は何ができるようになるか。その名前の private repository が存在する（または存在した）ことを知る。access はできない。攻撃に直接使えるものではない。

ただし `confidentiality.md` の第 1 段は「攻撃に限定しない。個人情報が漏れて困るのは本人へ害が及ぶからであり、事業上の機密は競合優位の喪失が問題である」と定める。private にしている意図が損なわれることは、この「本人への害」に当たる。

**利用者の過去の判断**

同じ repository について、plugin repository へ提案を引き渡す際に「出典元の repository 名をマスク化する」という指示があった。その指示は plugin への転記という場面のものだったが、理由（参照元が private である）は場面によらない。

**owner 名について**

同じ行に GitHub の owner 名が含まれるが、これは対象に含めない。この repository の `CLAUDE.md` が plugin repository の path として同じ owner 名を既に公開しており、public repository の owner として正当に公開されている情報である。

#### 提案0へのフィードバック

**結果:** 合意。a を採る。

### 決定

2026 年 7 月の steering にある参照元 private repository 名 7 箇所を「先行 repository」へ置き換える。local path を含む形で書かれていた箇所は、path ごと置き換える。

判断の根拠になっていたのは「既に同じ移行を済ませた前例がある」ことであり、その repository の名前ではない。置き換えても、なぜその形を採ったかは辿れる。

`design.md` 冒頭の依頼内容は原文だが、機密にあたる部分は置き換える。改変したことを同 file の冒頭へ注記する。

GitHub の owner 名は対象に含めない。この repository の `CLAUDE.md` が plugin repository の path として同じ owner 名を既に公開しており、public repository の owner として正当に公開されている情報である。
