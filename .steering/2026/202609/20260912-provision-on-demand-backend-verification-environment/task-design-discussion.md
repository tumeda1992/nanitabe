# 議論記録

> **表記について**: 実際の domain 名は `<hosted zone>` と表記し、既存 AWS resource の識別子は実値を伏せる。ユーザー発言や実行 log の引用内も同じ置き換えを行っている。domain の実値は `.env` の `ROUTE53_HOSTZONE_NAME` が持つ。


## 論点1: この環境で何が確認できれば「動作確認」になるか

**ステータス:** 分解済み

**種別:** TBDヒアリング

### イテレーション0: 確認対象と確認者を確定し、公開方式・DB 方式・データ準備の前提を決める

#### 提案0

**推奨:** a。常時課金ゼロという要求（「立てたい時だけ立てて 30 分で止まる」）と両立する唯一の案であり、b・d への拡張余地も残るため。

##### a. backend API 単体を、手元以外から到達できる場所で動かせれば動作確認とする

確認者は開発者本人。`POST /graphql` を curl や GraphQL client から叩き、query / mutation が期待どおり返ることを確認する。frontend は繋がない。

| 決まること | 内容 |
| --- | --- |
| 公開方式 | public subnet の Fargate task に public IP を付け、security group で接続元を絞る。ALB を持たない |
| HTTPS | なし（HTTP 直）。curl / GraphQL client からの利用なので mixed content が発生しない |
| DB | 同一 task 内の MySQL container。task 停止でデータも消える。起動時に `db:schema:load` + `db:seed` |
| データ準備 | seed（`DishEffortLevel` 14 件）に加えて、動作確認用 user を作る仕組みが要る |
| 常時課金 | ゼロ。停止中は 1 円もかからない |

##### b. スマホ実機など、開発者の PC 以外の端末から到達できることが主目的

確認者は開発者本人だが、確認する端末が PC ではない。a との差は「誰が確認するか」ではなく「どの端末の network から到達するか」。

security group の接続元をモバイル回線の IP まで広げるか、認証で守るかの判断が追加で要る。HTTPS の要否は、叩くのが GraphQL client アプリか browser かで変わる。browser から叩くなら HTTPS が要り、a の「ALB を持たない」前提が崩れる。

##### c. AWS 上の frontend と繋いだ end-to-end 確認環境の backend 側として使う

`frontend/terraform/envs/review/` に器だけ存在する review 環境と組み合わせ、画面から操作して確認する。

frontend は CloudFront（HTTPS）配信のため、browser から HTTP の backend を叩くと mixed content でブロックされる。したがって backend にも HTTPS が要り、ALB + ACM 証明書 + Route53 レコードが要る。ALB は task が停止していても課金が続く（月 $18 程度）ため、「立てたい時だけ」という要求とコスト面で衝突する。衝突を避けるには、起動操作のたびに ALB ごと `terraform apply` / `destroy` するか、ALB 以外の HTTPS 終端（API Gateway HTTP API + VPC Link 等）を選ぶ判断が追加で要る。

##### d. 本番 backend を将来 ECS へ移すための前段として、まず動作確認環境で型を作る

現在の本番 backend は自前 server 上の git pull 運用（`.github/workflows/backend-deploy.yml` は n8n webhook を叩くだけ）。この案では、動作確認環境で ECS 用の image build、migration の流し方、secret の渡し方を確立し、後で本番へ展開する。

この場合 DB は task 内 MySQL ではなく RDS が妥当になり（本番データ構造との差をなくすため）、RDS は停止しても 7 日で自動起動するため常時課金が発生する。今回作るものが最も重くなる。

#### 提案背景

**この論点を最上位に置く理由**

答えによって、公開方式（ALB + HTTPS が要るか public IP 直で足りるか）、DB 方式（RDS / task 内 MySQL / 既存本番 DB）、データ準備（user レコードと seed の要否）、`config.hosts` の設定、そして常時課金の有無が全て変わる。下位の論点（起動・停止手段、自動停止の実装、branch 運用、image build 経路、Terraform 配置、運用 document の置き場所）は全てこの答えに依存する。

**「本番相同性の確認」が今回は成立しないこと**

参照元 steering（private repository のため名称はマスク）は、検証用に別 app を作らず正本の app へ常設 branch を足すことで、build 設定と環境変数の乖離を構造的に防いだ。今回はこの利点が成立しない。backend の本番は AWS 上になく、repository 全体で ECS / Fargate への言及は 0 件である。ECS 上の動作確認環境は、本番とは別の実行基盤になる。

したがって「本番と同じ構成で確認する」は今回の目的になり得ない。成立するのは「production 設定の Rails が container image として起動し、外部から到達できる」ところまでである。ECS で立てる価値がどこにあるのかを確定させることが、この論点の核心になる。

**コスト構造（案の比較に必要な事実）**

- Fargate 0.25 vCPU / 0.5 GB は 1 時間あたり約 $0.012。30 分の起動なら 1 回あたり $0.006 程度で、起動時間課金は実質無視できる。
- 常時課金が発生するのは ALB（月 $18 程度）、RDS（最小構成で月 $12 程度、停止しても 7 日で自動起動）、NAT Gateway（月 $32 程度）。
- public subnet に public IP 付きで task を置けば NAT Gateway は不要になる。

「立てたい時だけ立てて 30 分で止める」という要求の実質は、停止中に課金が発生しないことである。この要求を額面どおり満たせるのは、常時課金 resource を一切持たない構成だけになる。案 c と d は、この要求と正面から衝突するため、衝突を承知で選ぶのか、要求のほうを緩めるのかをここで決める必要がある。

**案は排他ではないが、主目的は一つに決める必要がある**

a と b は公開範囲の差、c と d は作るものの重さの差である。複数が当てはまる場合でも、設計を決めるのは「今回これができれば完成とみなす」一つの基準であり、それを決めないと受け入れ基準が書けない。

#### 提案0へのフィードバック

**結果:** a を採用。ただし案 a に書いた DB 方式（task 内 MySQL）は否定され、既存の DB サーバへ接続する形になった。b は a を選ぶ理由であり別案ではないと整理された。

> うーん。色々混ざったかいとうになるな。このsteeringのゴールとしては「a. backend API 単体を、手元以外から到達できる場所で動かせれば動作確認とする」。なぜなら「b. スマホ実機など、開発者の PC 以外の端末から到達できることが主目的」。この後「c. AWS 上の frontend と繋いだ end-to-end 確認環境の backend 側として使う」。なんだったら多分「d. 本番 backend を将来 ECS へ移すための型を作る」。そして、今の開発環境もローカル外のDBサーバ繋いでるでしょ。今回出来上がるものもそれに繋いで

提案0は a と b を排他の選択肢として並べたが、実際には b が目的で a がその達成条件という関係だった。c と d は今回の非目標だが、将来の発展先として順に想定されている。

DB 方式を案 a の内部要素として書いたことで、確認対象の decision と DB の decision が同じ選択肢に混ざった。DB は別 decision として論点2へ分ける。

### 決定

このsteeringのゴールは、**backend API 単体が、開発者の PC 以外の端末から到達できる場所で動作することを確認できる状態**とする。

- 確認者は開発者本人。確認手段は `POST /graphql` を叩くこと。frontend は繋がない。
- この形をゴールにする理由は、スマホ実機など PC 以外の端末から到達できることが主目的であるため。ローカルの `docker compose` では、その端末から到達できない。
- AWS 上の frontend と繋いだ end-to-end 確認（提案0の c）は今回の非目標とし、この環境の次の発展先として想定する。
- 本番 backend の ECS 移行（提案0の d）はさらにその先の想定であり、今回の非目標とする。
- 今回の設計は、c と d へ育てられる形を、今回の要求を満たす範囲で優先する。育てるために今回の構成を重くすることはしない。
- DB は task 内に持たず、既存の DB サーバへ接続する。どの DB へ接続するかは論点2で決める。

## 論点2: 動作確認環境がどの DB へ接続するか

**ステータス:** 決定

**親論点:** 論点1

**種別:** TBDヒアリング

### イテレーション0: 接続先 DB のスキーマ範囲と、そこで受け入れるリスクを決める

#### 提案0

**推奨:** a。主目的（PC 以外の端末から実データで API を確認する）に最短で到達でき、動作確認用データを別途用意する仕組みが不要になるため。

##### a. 開発環境と同じ DB（同じ `DB_NAME`）へ接続する

ローカルの `docker compose` が今使っているのと同一の DB を、動作確認環境も使う。`DB_NAME` / `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASS` は現行の開発環境と同じ値を渡す。

| 観点 | 結果 |
| --- | --- |
| データ準備 | 不要。既存の user と献立データがそのまま使える |
| 起動時の処理 | migration だけ。`db:schema:load` と `db:seed` は不要 |
| 確認できること | 実データでの API 応答。スマホ実機から既存アカウントでログインして叩ける |
| 受け入れるリスク | 動作確認環境で migration を流すと、開発 DB のスキーマが変わる。載せるのは `main` 直前のコードなのでいずれ適用される migration だが、適用の順序と時期がローカル開発より先になる |
| 受け入れるリスク | 動作確認環境での mutation が開発 DB のデータを変える。ローカル開発と同じ DB を触るため、ローカルでの確認結果に影響する |

##### b. 同じ DB サーバ上に動作確認専用の `DB_NAME` を作る

接続先サーバは同じだが、database を分ける。

開発 DB のスキーマとデータは汚れない。一方で、起動のたびに `db:schema:load` + `db:seed` が要り、さらに動作確認用の user を作る仕組みが新たに要る（`seeds.rb` は `DishEffortLevel` 14 件だけで user を作らない）。スマホ実機から「既存の献立データを見る」確認はできなくなり、空の状態からの確認になる。

database の作成は DB サーバ側の操作であり、今回の Terraform の管理外になる。誰がいつ作るかを別途決める必要がある。

#### 提案背景

**ユーザー指示と、それによって確定したこと**

「今の開発環境もローカル外のDBサーバ繋いでるでしょ。今回出来上がるものもそれに繋いで」により、接続先サーバは既存の DB サーバで確定した。task 内に MySQL を持つ案は消えた。残るのは、その DB サーバ上のどの database へ繋ぐかである。

**調査で判明した接続先の実体**

- 開発 DB は container 内ではなく外部の server 上にあり、開発マシンから到達できることを確認済み。
- したがって「本番 backend は AWS 上に無い」という提案0の記述は誤りだった。正しくは Terraform の管理下にないだけである。この訂正は design.md の付録へも反映する。

**推奨を a にする理由と、そこで受け入れてもらう必要があるもの**

主目的は、スマホ実機など PC 以外の端末から backend API を叩けることである。この確認の価値は、実データで既存アカウントのまま叩けることに大きく依存する。b を選ぶと、その価値を得るために動作確認用の user とデータを別途用意する仕組みが必要になり、今回のゴール（論点1）に対して構成が重くなる。

ただし a は、動作確認環境の migration と mutation が開発 DB へ直接届くことを意味する。現在もローカル開発が同じ DB を直接触っているため新種のリスクではないが、「`main` 未マージのコードが開発 DB のスキーマを変える」という点は現状より一段進む。ここを受け入れられるかが a の採否を決める。

#### 提案0へのフィードバック

**結果:** a を受諾。提示した二つのリスク（未マージ migration が開発 DB のスキーマを変えること、mutation が開発 DB のデータを変えること）を受け入れたうえでの採用。

> a

### 決定

動作確認環境は、開発環境と同じ DB サーバ・同じ `DB_NAME` へ接続する。`DB_NAME` / `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASS` は現行の開発環境と同じ値を渡す。

この選択は次の二点を受け入れたうえで成立する。

- 動作確認環境で migration を流すと、開発 DB のスキーマが変わる。載せるのは `main` へ入る直前のコードなのでいずれ適用される migration だが、適用の時期がローカル開発より先になる。
- 動作確認環境からの mutation が開発 DB のデータを変える。ローカル開発と同じ DB を触るため、ローカルでの確認結果に影響しうる。

この決定の結果、起動時の DB 初期化（`db:schema:load`、`db:seed`）と動作確認用 user を用意する仕組みは不要になる。起動時に流すのは migration だけになる。

## 論点3: スマホ実機から backend へ到達する経路をどう作るか

**ステータス:** 決定

**親論点:** 論点1

**種別:** TBDヒアリング

### イテレーション0: 公開方式を決め、HTTPS の要否を確定する

#### 提案0

**推奨:** b。固定の host 名で到達でき、常時課金が増えず、後から HTTPS を足せるため。ただし、スマホ側で叩く手段が HTTPS を要求するなら b は成立せず、c か d になる。

##### a. Fargate task の public IP へ直接アクセスする

起動操作の出力として public IP を得て、それをスマホ側へ手で渡す。

- 追加 resource なし。常時課金ゼロ。
- 到達先が起動のたびに変わる。スマホ側に URL を保存しておけない。
- HTTPS なし。

##### b. public IP を、起動時に Route53 の A レコードへ書き込む

`<hosted zone>` の hosted zone へ、動作確認環境用の host 名（例: `verify-backend.nanitabe.<hosted zone>`）で A レコードを作る。起動処理が、その時の public IP でレコードを更新する。

- 到達先が固定 host 名になり、スマホ側に URL を保存できる。
- 常時課金は増えない。hosted zone は既に存在し、他用途でも使っている。
- HTTPS なし。`http://` で叩くことになる。
- レコードの TTL を短く（60 秒）しておく必要がある。停止中は前回の IP が残るため、停止中に叩くと応答しないのではなく、無関係の相手へ到達する可能性がある。停止時にレコードを消すか、到達しない値で上書きするかを決める必要がある。

##### c. ALB + ACM 証明書を常設し、HTTPS で公開する

- HTTPS で固定 host 名。browser からも native アプリからも制約なく叩ける。
- ALB が停止中も課金される（月 $18 程度）。「停止中に課金が発生する resource を構成へ含めない」という要件（論点1で確定）と正面から衝突する。この案を採るなら、その要件を緩める合意が別途要る。

##### d. 起動のたびに ALB を含めて作り、停止時に壊す

- HTTPS で固定 host 名。停止中の課金はゼロ。
- 起動・停止のたびに `terraform apply` / `destroy` が走り、起動完了まで数分かかる。ALB が起動するまで到達できない。
- 起動・停止が Terraform 実行になるため、操作の重さと失敗時の後始末（destroy 失敗で ALB が残る）を引き受けることになる。

#### 提案背景

**この論点で確定させること**

論点1で「開発者の PC 以外の端末から `POST /graphql` へ到達できる」ことをゴールに置いた。その到達経路を具体化する。到達先が固定か動的か、HTTPS が要るかが決まると、Terraform で作る resource の集合と、起動操作が何をするかが決まる。

**調査で判明した前提**

- VPC は default の 1 つだけで、subnet は 3 つとも public。private subnet も NAT Gateway も無いため、Fargate task を public subnet に public IP 付きで置く形が、追加の network resource を作らずに済む唯一の形になる。
- task の public IP が起動ごとに変わっても DB へ到達でき、DB 到達性はこの論点の判断材料から外れる。
- Route53 の hosted zone `<hosted zone>` が既に存在する。A レコードを足すことによる常時課金の増加は無い。

**HTTPS の要否がこの論点を分けること**

a と b は HTTP のみ、c と d は HTTPS を持つ。どちらが要るかは、スマホ側で何を使って叩くかで決まる。

- GraphQL client アプリ（Altair 等）や curl から叩くなら HTTP で足りる。
- repository 内の `native/`（React Native）アプリから叩く場合、iOS の App Transport Security が平文 HTTP をブロックする。例外設定を入れれば叩けるが、その設定を動作確認のためにアプリへ入れるかの判断が要る。
- スマホの browser から直接 GraphQL を叩く場合、HTTP のページから HTTP の API を叩く分にはブロックされない。

推奨を b にしているのは、HTTP で足りる場合に最も軽く、かつ後から c へ移行しても b の構成が無駄にならないためである。スマホ側の手段が HTTPS を要求するなら b は成立しないため、そこを確定させたい。

#### 提案0へのフィードバック

**結果:** b を採用。HTTPS は今回不要と確定した。提案0で「決める必要がある」と書いた停止中のレコード扱いは未回答のまま残る。

> b

### イテレーション1: 到達先の host 名と、停止中の A レコードの状態を確定する

#### 提案1

**host 名:** `verify-backend.nanitabe.<hosted zone>`

既存の frontend 本番が `nanitabe.<hosted zone>` を使っているため、その下へ用途を表す label を足す。将来 frontend 側の確認環境を作るときに `verify-front.nanitabe.<hosted zone>` と並べられる。

**停止中の A レコード:** 停止処理で削除する。

起動処理が A レコード（TTL 60 秒）をその時の public IP で作成し、停止処理が同じレコードを削除する。停止中はこの host 名が名前解決に失敗する。

**この形を選ぶ理由**

停止中にレコードを残す選択は取れない。Fargate task の public IP は停止時に AWS へ返却され、別の AWS 利用者へ再割当される。古い IP を指したまま叩くと、認証情報や mutation の内容が無関係の第三者のホストへ送信される。

残さない形は二つある。レコードを削除する形と、到達しない値（`192.0.2.1` など、ドキュメント用に予約され誰も使わない address）へ上書きする形である。どちらも、停止処理が失敗すれば実 IP が残るという点では同じ危険度を持つ。

削除を選ぶのは、停止中の状態が名前解決の失敗として現れ、「停止している」と「設定を間違えている」を区別しやすいためである。上書きの場合、名前解決は成功して接続だけがタイムアウトするため、停止中なのか経路の問題なのかが利用者から見て分かれない。

**Elastic IP を使って IP を固定する案を採らない理由**

Elastic IP を割り当てれば host 名と IP の対応が固定され、レコードの更新自体が不要になる。しかし Elastic IP は、どこにも割り当てられていない間も課金される（月 $3.6 程度）。金額は小さいが、論点1で確定した「停止中に課金が発生する resource を構成へ含めない」という要件に抵触する。今回はレコードを毎回更新する側を選ぶ。

#### 提案背景

提案0への feedback で b が採用され、HTTPS が不要であることも確定した。b の内部にはまだ二つの未確定がある。到達先の host 名そのものと、停止中にレコードをどう扱うかである。どちらも「到達先を指す identifier が、どの状態で何を指すか」という一つの decision の内側にあるため、同じ論点で確定させる。

停止中のレコード扱いは、提案0では選択肢を示さず「決める必要がある」とだけ書いた。実害の内容（public IP の再割当による第三者への送信）を明示したうえで、選べる形が実質二つしかないことを示す。

#### 提案1へのフィードバック

**結果:** host 名を修正。`verify` という語の選択自体が誤りだと指摘された。停止時に A レコードを削除する点と Elastic IP を採らない点は受諾。

> ElasticIPを使わない件は承知。細かい話で、host名は review-backend-nanitabe.<hosted zone>(フロントはreview-nanitabe.<hosted zone>)がいい。多分subsubドメインのホストゾーン取っていないため。そして、terraformの単体テストではverify-infraを使っていたけど、それは意味通り、通るかをどうかを検証するための名前だった。今回の名前はreviewをすること

`verify` は既に別の意味で使われている語だった。`nanitabe-front-verify-infra` と `DEPLOY_ENV: verify-infra` は「Terraform の構成が通るかどうかを検証する」用途の名前であり、今回の「変更内容をレビューする環境」とは意味が違う。提案1はこの既存用法を確認せずに `verify` を選んでいた。

### イテレーション2: `review` を用いた host 名を確定し、`verify` との使い分けを設計へ残す

#### 提案2

**host 名:** `review-backend-nanitabe.<hosted zone>`

frontend 側の確認環境を作るときは `review-nanitabe.<hosted zone>` を使う。今回は backend だけを作るため、frontend 側のレコードは作らない。

**`review` と `verify` の使い分け:**

| 語 | 意味 | 既存の使用例 |
| --- | --- | --- |
| `review` | 変更内容をレビューするための環境 | `review-<参照元 repository>.<hosted zone>`（参照元 steering） |
| `verify` | 構成が通るかどうかを検証するための単体テスト | `nanitabe-front-verify-infra.<hosted zone>`、`DEPLOY_ENV: verify-infra` |

この区別は host 名だけでなく、ECR repository 名、Terraform の stage 名、環境変数の値など、今回作るもの全体で一貫させる。今回作るのはレビュー環境なので `review` を使う。

**停止中の A レコード:** 提案1のとおり、停止処理で削除する。TTL は 60 秒。

#### 提案背景

**host 名をフラットな 1 ラベルにする理由**

feedback では「sub-sub ドメインの hosted zone を取っていないため」が理由として挙がったが、Route53 の動作としてはこれは制約にならない。`<hosted zone>` の hosted zone は配下の名前空間全体を管理し、`nanitabe.<hosted zone>` へ NS 委譲した子 zone は存在しない。したがって `<hosted zone>` の zone へ `a.b.<hosted zone>` 形式の A レコードを直接置いても解決する。HTTPS を使わないため、ワイルドカード証明書が 1 ラベルしかカバーしないという制約も今回は効かない。

それでもフラットな 1 ラベルを採るのは、既存レコードが例外なくその形だからである。zone 内の A / CNAME レコードは、用途と対象を 1 ラベル内でハイフン連結する形で統一されており、sub-sub ドメインは 1 件も存在しない。ここだけ階層を掘ると、レコード一覧を読む人が「なぜこれだけ形が違うのか」を毎回考えることになる。

**frontend と backend の非対称について**

`review-nanitabe`（frontend、component を表す label なし）と `review-backend-nanitabe`（backend、`backend` あり）は非対称に見えるが、既存の本番レコードが frontend と backend で同じ非対称を持つ。既存慣習の踏襲として扱う。

#### 提案2へのフィードバック

**結果:** host 名（`review-backend-nanitabe.<hosted zone>`）と `review` / `verify` の使い分けは受諾。一方で、提案0で確定したはずの「HTTPS 不要」へ差し戻しがかかった。

> 提案3についてはok。ただ提案0について戻って考えたい。この後frontendがスマホとかで触るから、httpsは必要なんじゃないの？

指摘は正しい。将来 frontend の確認環境（論点1の c）へ進むと、frontend は CloudFront 配信の HTTPS ページになり、スマホの browser から backend を叩く。HTTPS ページから HTTP の API を叩くと mixed content でブロックされるため、その時点で backend にも HTTPS が必須になる。

さらに、提案0から提案2までの案には、この差し戻しで初めて見えた構造的な問題がある。論点1で「c へ育てられる形を優先する」と決めたにもかかわらず、提案2の構成（起動時に Route53 の A レコードを実 IP で更新する）は、c で HTTPS を足す段階で捨てることになる。HTTPS 終端を前に置くと、その終端の DNS 名は固定になり、task の IP を追いかける仕組み自体が不要になるためである。

### イテレーション3: HTTPS を今回の構成へ含める形を決める

#### 提案3

**推奨:** b。停止中の課金ゼロという要件を保ったまま HTTPS を得られ、かつ c へ進むときに捨てる部品が出ないため。

##### a. 今回は HTTP のままにし、c へ進むときに HTTPS 終端を足す

提案2の構成を維持する。`review-backend-nanitabe.<hosted zone>` の A レコードを起動時に実 IP で更新し、停止時に削除する。

c へ進む段階で HTTPS 終端を前に置き、その時点で Route53 を直接更新する仕組みは捨てる。今回の構成は最も軽いが、c で作り直しになる部分を含むことが確定している。

##### b. API Gateway HTTP API を HTTPS 終端として置き、ECS task へプロキシする

| 構成要素 | 役割 | 停止中の課金 |
| --- | --- | --- |
| `aws_apigatewayv2_api`（HTTP API） | HTTPS 終端。`$default` route で全 request を通す | なし（request 従量のみ） |
| `aws_apigatewayv2_domain_name` + ACM 証明書 | `review-backend-nanitabe.<hosted zone>` を API Gateway へ割り当てる | なし（ACM 証明書は無料） |
| Route53 A（alias） | 上記 domain を指す。API Gateway 側の DNS 名は固定なので、このレコードは常設で更新不要 | なし |
| `aws_apigatewayv2_integration`（`HTTP_PROXY`） | ECS task の public IP へ転送する。起動時にこの URI を更新する | なし |

起動処理は Route53 ではなく integration の URI を更新する。停止処理は URI を到達しない値（`192.0.2.1` 等）へ戻す。Route53 レコードは常設のままなので、停止中に第三者の host を指す事故が起きない。

frontend が既に HTTP API（`aws_apigatewayv2_api`）を使っており、`frontend/terraform/modules/apigateway/main.tf` に `$default` route と auto_deploy stage の pattern がある。

弱点: API Gateway から ECS task への転送は HTTP であり、VPC の外を通る。両端とも AWS 内だが、VPC 内終端と比べれば弱い。また task の port を `0.0.0.0/0` へ開けることになるため、public IP を知っていれば API Gateway を経由せず HTTP で直接叩ける。host 名からは IP が分からないため、IP を知らない相手からは到達できない。

##### c. ALB + ACM 証明書を常設する

VPC 内で HTTPS を終端し、task へは VPC 内の通信だけが届く。task の port も ALB の security group からのみ許可でき、b の弱点が両方とも消える。

ALB は task が停止していても課金される（月 $18 程度）。論点1で確定した「停止中に課金が発生する resource を構成へ含めない」を緩める合意が別途要る。

##### d. 起動のたびに ALB を作り、停止時に壊す

c の構成を保ったまま停止中の課金をゼロにする。ACM 証明書は常設のまま使い回せる。

起動操作が ALB の作成を含むため、到達できるまで数分かかる。停止が失敗すると ALB が残り、気づかないまま課金が続く。起動・停止の操作が Terraform の apply / destroy になるため、操作の重さも上がる。

#### 提案背景

**差し戻しによって変わった前提**

提案0では「スマホから何で叩くか」を判断材料として示し、GraphQL client や curl から叩くなら HTTP で足りると書いた。今回のゴール（論点1）は backend API 単体の確認であり、その範囲では今も HTTP で足りる。

変わったのは、c を「いつか検討する将来」ではなく「この後に進む次の段階」として扱う点である。次の段階で必ず HTTPS が要るなら、今回 HTTP 専用の到達経路を作り込むと、その部分は一度しか使われない。

**Route53 を直接更新する形が c で捨てられる理由**

HTTPS 終端（API Gateway でも ALB でも）を前に置くと、利用者が叩く host 名はその終端を指す。終端の DNS 名は task の起動・停止に関わらず固定であるため、起動のたびに Route53 を書き換える必要がなくなる。書き換えの対象は終端の裏側（integration URI や target group）へ移る。

つまり「起動時に Route53 を更新する」は、HTTPS 終端を持たない構成でだけ必要な仕組みである。

**b を推奨する理由と、そこで受け入れるもの**

b は、停止中の課金ゼロ（論点1の要件）と HTTPS を両立する唯一の案である。c は要件と衝突し、d は要件を満たすが起動の重さと後始末の失敗リスクを持ち込む。

b で受け入れるのは、API Gateway から task への転送が VPC 外を通ることと、task の port が公開されることである。動作確認環境として許容できるかが b の採否を決める。許容できないなら c（要件を緩める）か d（起動を重くする）になる。

#### 提案3へのフィードバック

**結果:** 一度 a（HTTP のまま）へ寄せたが、その過程で ACM 証明書を ECS task へ付けられない事実が共有され、最終的に b を選ぶ方向になった。

> え、大げさなものばかりあがってるけど、https://review-backend-nanitabe.<hosted zone> にroute53でECSを割り当てれば良いんじゃないの？

この案は成立しない。Route53 は名前から IP を答えるだけで、TLS 終端を提供しない。`https://` で到達するには、接続先が該当 host 名の証明書を提示する必要がある。また Route53 の alias が指せるのは ALB / CloudFront / API Gateway / S3 等であり、ECS task は対象外のため、A レコードへ public IP を書く形しか取れない。

この指摘に対し、assistant は「c で捨てる部品が出る」ことを理由に HTTPS 構成を推していたが、実際に捨てるのは起動・停止処理が Route53 を叩く数行だけであり、規模を過大に見積もっていた。それを理由に今回の構成を重くするのは論点1の決定に反するため、推奨を a へ戻した。

> そうか。ACMの証明書がECSに確かに付けられないな。で、フロントエンドのブラウザから見えるところにhttpと書くわけにもいかない。ワークアラウンドだけどbをえらぶか？

a へ戻した後、frontend の browser から見える位置に `http://` の URL を置くことが受け入れられないという判断が示され、b が選ばれた。

### イテレーション4: b を採用し、公開経路の全体を確定する

#### 提案4

**到達経路:**

```text
  スマホ / browser
       |
       |  https://review-backend-nanitabe.<hosted zone>/graphql
       v
  Route53 A（alias、常設）
       |
       v
  API Gateway HTTP API（HTTPS 終端、ACM 証明書）
       |
       |  http、Host ヘッダを review-backend-nanitabe.<hosted zone> へ上書き
       v
  ECS Fargate task（public subnet、public IP）
       |
       v
  既存の DB サーバ（MySQL）
```

**構成要素:**

| 要素 | 内容 | 起動・停止で変わるか |
| --- | --- | --- |
| `aws_acm_certificate` | `review-backend-nanitabe.<hosted zone>` の証明書。`ap-northeast-1` で発行し、DNS 検証する | 変わらない |
| `aws_apigatewayv2_api` | HTTP API。`$default` route と auto_deploy stage | 変わらない |
| `aws_apigatewayv2_domain_name` + `aws_apigatewayv2_api_mapping` | host 名を API Gateway へ割り当てる | 変わらない |
| `aws_route53_record`（A、alias） | API Gateway の regional domain を指す。常設 | 変わらない |
| `aws_apigatewayv2_integration`（`HTTP_PROXY`） | task の public IP へ転送する。`request_parameters` で `overwrite:header.Host` を host 名へ固定する | **起動時に URI を実 IP へ更新し、停止時に到達しない値へ戻す** |

**IP 直アクセスを塞ぐ仕組み:**

integration で Host ヘッダを host 名へ上書きし、Rails の `config.hosts` にはその host 名だけを許可する。API Gateway を経由した request は Host が host 名なので通り、public IP を直接叩いた request は Host が IP になるため `Blocked hosts` で弾かれる。`config.hosts` は既存の `BACKEND_PROD_HOST` を読む仕組み（`backend/config/application.rb`）へ値を渡すことで満たせる。

**残る弱点:**

API Gateway から task への転送は HTTP であり、VPC の外を通る。両端とも AWS 内だが、ALB のように VPC 内で終端する構成に比べれば弱い。これを消すには ALB が要り、ALB は停止中も課金されるため、今回は受け入れる。

#### 提案背景

**ACM 証明書の制約から導かれたこと**

ACM が発行する証明書は ALB / CloudFront / API Gateway へ結び付けることしかできず、ECS task へ渡せない。task 自身で TLS を終端するには Let's Encrypt 等で証明書を取得することになり、起動のたびに取得すれば rate limit に当たるため証明書の永続化が要り、DNS-01 検証のために task へ Route53 の権限を渡すことになる。API Gateway を置くより重い。

したがって、HTTPS を求める限り終端は AWS の managed service（API Gateway / ALB / CloudFront）のいずれかになる。CloudFront はオリジン更新の反映に数分から十数分かかり、30 分で落ちる環境には合わない。ALB は停止中も課金される。残るのが API Gateway である。

**今回の段階で入れる理由**

論点1では「c へ育てるために今回の構成を重くしない」と決めた。これは不確実な将来のために先回りしないという意味であり、c は「この後に進む」と確定した次段階である。かつ c でも停止中課金ゼロを保つなら、そこでも ALB は選べず同じ API Gateway 構成になる。今回入れても後で入れても構成は同じであり、後回しにすると起動・停止処理を Route53 更新から integration URI 更新へ書き換える手戻りが生じる。

**弱点を承知で選ぶことの位置づけ**

API Gateway で ECS task を直接プロキシする形は、ALB を挟む一般的な構成と比べて変則的である。停止中課金ゼロという制約を満たすために選んでおり、その制約が変われば ALB へ移る余地を残す。

#### 提案4へのフィードバック

**結果:** 受諾。

> ok

### 決定

動作確認環境へは `https://review-backend-nanitabe.<hosted zone>` で到達する。経路は次のとおり。

```text
  スマホ / browser
       |
       |  https://review-backend-nanitabe.<hosted zone>/graphql
       v
  Route53 A（alias、常設）
       |
       v
  API Gateway HTTP API（HTTPS 終端、ACM 証明書）
       |
       |  http、Host ヘッダを review-backend-nanitabe.<hosted zone> へ上書き
       v
  ECS Fargate task（public subnet、public IP）
```

- ACM 証明書、HTTP API、custom domain、Route53 の A レコードは常設で、停止中も課金されない。起動・停止で変わるのは `HTTP_PROXY` integration の URI だけとする。起動時に task の public IP を書き、停止時に到達しない値（`192.0.2.1` 等）へ戻す。
- public IP を直接叩かれることは、integration で Host ヘッダを host 名へ上書きし、Rails の `config.hosts` にその host 名だけを許可することで塞ぐ。IP 直アクセスは Host が IP になるため `Blocked hosts` で弾かれる。
- API Gateway から task への転送が HTTP であり VPC の外を通る点は、弱点として受け入れる。これを消すには ALB が要り、ALB は停止中も課金されるため、停止中課金ゼロの要件（論点1）を優先する。
- ALB / CloudFront / task 自身での TLS 終端はいずれも採らない。ALB は停止中課金、CloudFront はオリジン更新の反映が数分から十数分かかり 30 分で落ちる環境に合わず、task 自身での終端は Let's Encrypt の証明書取得と永続化が必要になり API Gateway より重い。
- `review` と `verify` を使い分ける。`review` は変更内容をレビューする環境（`review-<参照元 repository>.<hosted zone>` が先例）、`verify` は構成が通るかを検証する単体テスト（`nanitabe-front-verify-infra`、`DEPLOY_ENV: verify-infra` が先例）。今回作るものは host 名、ECR repository 名、Terraform の stage 名、環境変数の値まで一貫して `review` を使う。

## 論点4: 動作確認環境へ何を載せ、どこで image を build するか

**ステータス:** 決定

**親論点:** 論点1

**種別:** TBDヒアリング

### イテレーション0: 載せる対象の決め方と、build の契機・実行場所を決める

#### 提案0

**推奨:** a。載せ替えが git の操作だけで完結し、起動操作に build 時間が乗らないため。

##### a. 常設の `review` branch を作り、push を契機に CodePipeline が build する

参照元 steering の運用をそのまま持ち込む。

- 確認対象の branch を `main` へ rebase してから `git push -f origin <確認対象>:review` で載せる。
- `review` branch に何が載っているかは保証しない。確認する人が、開く前に必ず自分の確認対象を force push する。
- 確認が終わった後の後始末をしない。次に確認する人の force push で上書きされる。
- push を契機に CodePipeline が起動し、CodeBuild が image を作って ECR へ push する。
- 起動操作は ECR にある最新 image で task を起動するだけになり、build 時間が乗らない。

`frontend/terraform/modules/cicd/` が同じ構造（CodePipeline の Source に `CodeStarSourceConnection`、Build に CodeBuild）を持つため、module の形を流用できる。既存の `aws_code_connection_id_to_github` をそのまま使え、GitHub 側に AWS credentials を置く必要がない。

CodePipeline は `pipeline_type = "V2"` を指定する。V1 は active pipeline に月 $1 の固定課金があるが、V2 は実行時間のみの課金であり、停止中の課金がゼロという要件を保てる。

##### b. 常設の `review` branch を作り、起動操作が CodeBuild を直接起動する

branch 運用は a と同じだが、CodePipeline を作らず、起動操作が `aws codebuild start-build` を叩いて build を待ってから task を起動する。

構成要素は減る。一方で、起動操作のたびに `bundle install` を含む image build が走るため、到達できるまで数分から十分近くかかる。30 分で落ちる環境に対して、その待ち時間が占める割合が大きい。

##### c. branch を固定せず、起動操作で対象 branch を指定する

`review` branch を作らず、起動操作の引数として branch 名を渡す。CodeBuild の source version にその branch を指定して build する。

force push の手間がなくなる一方、「今この環境に何が載っているか」を git から確認できなくなる。参照元の運用が持っていた「`review` の HEAD を見れば載っているものが分かる」という性質を失う。

##### d. 手元で image を build して ECR へ push する

AWS 側の build resource を作らない。手元の docker で build し、ECR へ push してから起動する。

build 環境が各自の手元になるため、CPU architecture（Fargate は `X86_64` か `ARM64` を task definition で指定する）と手元のマシンの差を毎回意識することになる。build の再現性も手元の状態に依存する。

#### 提案背景

**この論点で決めること**

論点1から論点3で、環境がどこにあり、どう到達するかが決まった。残るのは、その環境に「何が載るか」をどう決め、載せるものをどこで image にするかである。起動・停止の操作手段（次の論点）は、ここで決まる build 契機の上に乗る。

**参照元の運用から持ち込むもの**

参照元 steering は、確認用の常設 branch へ force push する運用を採り、後始末を運用へ含めなかった。後始末を含めないのは、規約が守られなかったときにより悪い状態を作らないためである。branch に何が載っているかを保証せず、確認する人が開く前に自分で載せる、という形にすることで、「前の人の後始末漏れ」という状態自体をなくしている。

この性質は今回も有効なため、a と b で同じ運用を採る。

**build 契機を push に置くか起動時に置くか**

環境が 30 分で落ちることが、この判断に効く。起動操作に build を含めると、到達できるまでの待ち時間が利用可能時間を削る。Rails の image build は `bundle install` を含むため短くない。

push 契機で build しておけば、起動操作は ECR の image で task を起動するだけになり、待ち時間は task 起動の 1 分から 2 分に収まる。代償として、force push のたびに build が走る。参照元の環境も push 契機で build する形であり、同じ挙動になる。

**GitHub 側に AWS credentials を置かない理由**

現在、GitHub Actions の workflow は AWS を一切触っていない（`.github/workflows/` 配下に AWS を参照する記述なし）。frontend の deploy は AWS 側の CodePipeline が `CodeStarSourceConnection` で GitHub を見る形になっており、GitHub 側に credentials も OIDC の信頼設定も存在しない。

build を GitHub Actions で行うと、この前提を崩して credentials か OIDC を新たに用意することになる。既存の connection を流用できる CodePipeline / CodeBuild を使えば、その判断を持ち込まずに済む。

**ECR repository 名**

`nanitabe-back/rails-on-ecs/review` とする。既存の frontend が `nanitabe-front/next-js-on-lambda/{prod,verify-infra}` という `<app>-<component>/<実行形態>/<stage>` の形を採っているため、それに揃える。`stage` に `review` を使うのは論点3の決定による。

#### 提案0へのフィードバック

**結果:** 受諾。

> a

### 決定

動作確認環境へ載せるものは、常設の `review` branch が持つ内容とする。

**branch 運用**

- 確認対象の branch を `main` へ rebase してから `git push -f origin <確認対象>:review` で載せる。
- `review` branch に何が載っているかは保証しない。確認する人は、開く前に必ず自分の確認対象を force push する。
- 確認が終わった後の後始末を運用へ含めない。次に確認する人の force push で上書きされる。後始末を運用へ入れないのは、規約が守られなかったときにより悪い状態を作らないためである。

**build 経路**

- `review` branch への push を契機に CodePipeline が起動し、CodeBuild が image を作って ECR へ push する。
- CodePipeline の Source は既存の `CodeStarSourceConnection`（`aws_code_connection_id_to_github`）を流用する。GitHub 側に AWS credentials も OIDC の信頼設定も置かない。現在 `.github/workflows/` は AWS を一切参照しておらず、この前提を崩さない。
- `pipeline_type = "V2"` を指定する。V1 は active pipeline に月 $1 の固定課金があり、停止中課金ゼロの要件（論点1）に抵触するため。
- 構造は `frontend/terraform/modules/cicd/`（`codebuild` と `codepipeline` の 2 階層）を流用する。
- 起動操作は ECR にある image で task を起動するだけとし、build を含めない。環境が 30 分で落ちるため、起動のたびに `bundle install` を含む build を待つと利用可能時間を削るためである。

**ECR repository 名**

`nanitabe-back/rails-on-ecs/review` とする。既存の `nanitabe-front/next-js-on-lambda/{prod,verify-infra}` が採る `<app>-<component>/<実行形態>/<stage>` の形に揃える。

## 論点5: ECS 上で動く image の中身と起動処理をどうするか

**ステータス:** 決定

**親論点:** 論点1

**種別:** TBDヒアリング

### イテレーション0: image の作り方、起動 command、architecture を確定する

#### 提案0

**image の作り方**

`backend/buildOnEcs/Dockerfile` を新設する。既存の `backend/Dockerfile` は変更しない。

既存の `backend/Dockerfile` は application code を COPY せず、`docker-compose.yml` の volume mount で code を持ち込む前提になっている。ECS では volume mount がないため、code を含む image が要る。既存を書き換えると開発環境の前提が崩れるため、別 file にする。frontend が `frontend/buildOnLambda/Dockerfile` を通常の `frontend/Dockerfile` と別に持っているのと同じ形である。

新しい Dockerfile が既存と変える点は次の三つになる。

- application code を COPY する。
- `bundle install` を build 時に済ませる。既存の開発用 `entrypoint.sh` は起動のたびに `bundle install` を実行するが、image に含めておけば起動が速くなる。
- 起動 command を開発用 `entrypoint.sh` ではなく、ECS 用の起動 script にする。

**起動処理**

```sh
#!/bin/bash
set -e

bundle exec rails db:migrate

exec bundle exec puma -b "tcp://0.0.0.0:${PORT}"
```

- `set -e` により、migration が失敗した場合は puma を起動せず task が異常終了する。壊れた状態で到達可能になることを防ぐ。
- `exec` で puma をプロセス 1 に置き換える。これがないと ECS の停止要求（SIGTERM）が puma へ届かず、停止が強制終了まで待たされる。
- `db:migrate` は開発 DB のスキーマを変える。論点2で受け入れ済み。
- 開発用 `entrypoint.sh` が行っている `bundle install`、test 用 DB の migrate、`tail -f log/development.log` による常駐は、いずれも ECS では行わない。

**環境変数**

| 変数 | 値 | 理由 |
| --- | --- | --- |
| `RAILS_ENV` | `production` | 専用環境を新設せず既存の設定を使う。`config/environments/` と `database.yml` へ新しい環境を足す必要がない |
| `RAILS_LOG_TO_STDOUT` | `1` | 未設定だと log が file 出力のみになり CloudWatch Logs へ出ない |
| `PORT` | `18101` | 開発環境と同じ port にする。API Gateway の integration URI に port を書くため、外部からは見えない |
| `BACKEND_PROD_HOST` | `review-backend-nanitabe.<hosted zone>` | `config.hosts` の許可 host。API Gateway が Host ヘッダをこの値へ上書きする（論点3） |
| `DB_*`、`RAILS_MASTER_KEY` | 既存の開発環境と同じ値 | 値の渡し方は別論点 |

**CPU architecture**

`ARM64` とする。Fargate の ARM64 は X86_64 より約 20% 安く、開発機も aarch64 であるため gem のネイティブ拡張（`mysql2` 等）の挙動が揃う。CodeBuild も ARM の build 環境を選ぶ。

#### 提案背景

**実測で確定した事実**

提案の前提を、開発用 container 内で `RAILS_ENV=production` を実行して確認した。

| 確認したこと | 結果 |
| --- | --- |
| production で Rails が boot するか | boot する。`eager_load=true`。`assets:precompile` を行っていない状態でも boot は通る |
| production で GraphQL が応答するか | `POST /graphql` が HTTP 200 を返す。body は `__typename field requires authentication` という認証エラーで、GraphQL 層まで到達している |
| `config.hosts` が許可外の Host を弾くか | 許可外の Host（IP 形式）を送ると **HTTP 403**。論点3 で設計した IP 直アクセスの遮断が、実際に効くことを確認した |
| puma の起動 command | `puma -b 0.0.0.0` は `Invalid URI: 0.0.0.0` で exit code 1 になる。`-b tcp://0.0.0.0:PORT` の URI 形式が必要。開発用 `entrypoint.sh` が `rails s -b 0.0.0.0` で動いているのは Rails が変換しているため |

**`assets:precompile` を行わない理由**

production では `config.assets.compile = false` であり、precompile 済み manifest がないと assets を参照する view のレンダリングが失敗する。ただし今回叩くのは `POST /graphql` だけで、view を返さない。boot 自体は manifest がなくても通ることを実測で確認した。

`admin/` 配下の管理画面は view を持つため、この image では開けない。動作確認の対象が GraphQL API であることは論点1で確定しているため、今回はこれを制約として受け入れる。

**`RAILS_ENV` に専用の環境を作らない理由**

`review` 専用の Rails 環境を作る選択肢もあるが、`config/environments/review.rb` と `database.yml` の `review:` セクションを新設することになり、開発環境と本番環境の設定が三分岐する。今回必要なのは production 相当の動作であり、差分は環境変数で表現できる範囲に収まる。

#### 提案0へのフィードバック

**結果:** 受諾。

> ok

### 決定

ECS で動かす image と起動処理を次のとおりにする。

- `backend/buildOnEcs/Dockerfile` を新設し、既存の `backend/Dockerfile` は変更しない。新しい Dockerfile は application code を COPY し、`bundle install` を build 時に済ませる。frontend が `frontend/buildOnLambda/Dockerfile` を別に持つのと同じ形を採る。
- 起動処理は、`set -e` のうえで `bundle exec rails db:migrate` を実行し、`exec bundle exec puma -b "tcp://0.0.0.0:${PORT}"` で puma をプロセス 1 に置き換える。`set -e` は migration 失敗時に到達可能な状態を作らないため、`exec` は ECS の SIGTERM が puma へ届くために必要である。
- 開発用 `entrypoint.sh` が行う `bundle install`、test 用 DB の migrate、`tail -f log/development.log` による常駐は ECS では行わない。
- 環境変数は `RAILS_ENV=production`、`RAILS_LOG_TO_STDOUT=1`、`PORT=18101`、`BACKEND_PROD_HOST=review-backend-nanitabe.<hosted zone>` とする。`DB_*` と `RAILS_MASTER_KEY` は開発環境と同じ値を使い、渡し方は別論点で決める。
- CPU architecture は `ARM64` とする。Fargate の ARM64 は X86_64 より約 20% 安く、開発機も aarch64 であるため native 拡張を持つ gem の挙動が揃う。CodeBuild も ARM の build 環境を使う。
- `assets:precompile` は行わない。その結果 `admin/` 配下の管理画面はこの image では開けない。動作確認の対象が GraphQL API であるため制約として受け入れる。
- `RAILS_ENV` に `review` 専用の Rails 環境を新設しない。`config/environments/` と `database.yml` を三分岐させず、差分を環境変数で表現する。

この決定は、開発用 container 内で `RAILS_ENV=production` を実行した実測に基づく。production で Rails が boot し、`POST /graphql` が HTTP 200 を返し（body は認証エラーで GraphQL 層まで到達）、`config.hosts` の許可外 Host が HTTP 403 で弾かれることを確認した。また `puma -b 0.0.0.0` は `Invalid URI` で異常終了し、`-b tcp://0.0.0.0:PORT` の URI 形式が必要であることも実測で確定している。

## 論点6: 起動・停止をどう操作し、30 分の自動停止をどう実装するか

**ステータス:** 決定

**親論点:** 論点1

**種別:** TBDヒアリング

### イテレーション0: 操作の実体と、自動停止を担う仕組みを決める

#### 提案0

**推奨:** a。Lambda を書かずに済み、停止に必要な処理が AWS API の呼び出し 2 つで表現できるため。

**前提として先に決めること: ECS service ではなく standalone task を使う**

三案に共通する。ECS service で `desiredCount` を 0 と 1 で切り替える形も取れるが、service は task が終了すると自動で再起動する。30 分で落とす運用と正面から競合し、自動停止のたびに「停止したい側」と「起動し続けたい側」が綱引きになる。`RunTask` で起動する standalone task なら、停止は task の終了そのものになる。

##### a. ローカルの script が AWS CLI を叩き、自動停止は EventBridge Scheduler が AWS API を直接呼ぶ

起動 script（`scripts/review_backend/start.sh`）が行うこと:

1. `aws ecs run-task` で task を起動する。
2. `aws ecs wait tasks-running` で RUNNING になるまで待つ。
3. task の ENI から public IP を取得する（`describe-tasks` で `networkInterfaceId` を得て `describe-network-interfaces` を引く）。
4. `aws apigatewayv2 update-integration` で integration URI を `http://<public IP>:18101/{proxy}` へ更新する。
5. EventBridge Scheduler へ 30 分後の one-time schedule を 2 つ作る。既に同名の schedule があれば削除してから作る。
6. 到達 URL と自動停止の予定時刻を標準出力へ出す。

自動停止を担う 2 つの schedule は、Lambda を経由せず AWS API を直接呼ぶ（universal target）。

| schedule | target | 効果 |
| --- | --- | --- |
| 停止 | `aws-sdk:ecs:stopTask` | task を終了させる |
| 経路の遮断 | `aws-sdk:apigatewayv2:updateIntegration` | integration URI を到達しない値（`http://192.0.2.1:18101/{proxy}`）へ戻す |

停止 script（`scripts/review_backend/stop.sh`）は、同じ 2 つの操作を即座に実行し、schedule を削除する。手動停止と自動停止で起きることが同じになる。

schedule は実行後に自動削除する設定（`ActionAfterCompletion: DELETE`）にし、停止中に schedule が残らないようにする。

##### b. 停止処理を Lambda にまとめ、EventBridge Scheduler がその Lambda を呼ぶ

a と同じ流れだが、「task 停止 + integration URI を戻す」を 1 つの Lambda に入れ、schedule は 1 つにする。

停止処理が 1 箇所になり、2 つの schedule の片方だけが成功する状態が起きない。一方で Lambda の実装と deploy 経路（Terraform、code の置き場所、ランタイム更新）が新たに増える。

##### c. task 自身が 30 分で終了し、ローカル script は起動だけを行う

起動 script は task 起動と integration URI 更新だけを行い、自動停止は task の起動 command を `timeout 1800 bundle exec puma ...` にすることで実現する。EventBridge Scheduler も Lambda も作らない。

AWS 側の構成要素は最も少ない。ただし task が自分で終了した後、integration URI を戻す主体がいない。task 内から `trap` で AWS CLI を呼ぶ形にすると、task role へ API Gateway の更新権限を与えることになり、かつ強制終了時に確実に走る保証がない。停止中に URI が解放済みの IP を指し続ける状態を許すことになる。

#### 提案背景

**この論点で決めること**

論点3で「起動・停止で変わるのは integration URI だけ」、論点4で「起動操作は ECR の image で task を起動するだけ」と決めた。残るのは、その操作を誰の手元で何が実行し、30 分後の停止を何が担うかである。

**停止処理が 2 つの操作から成ること**

停止は task を止めるだけでは終わらない。integration URI が解放済みの public IP を指したままになると、その IP が別の AWS 利用者へ再割当された後、URL を叩いた request が第三者のホストへ届く（論点3）。したがって停止処理は「task の終了」と「URI を到達しない値へ戻す」の 2 つが揃って完了する。

この 2 つを 1 単位として扱えるかが、三案の主な違いになる。a は 2 つの schedule に分かれ、b は Lambda 内で 1 単位になり、c は後者が欠ける。

**a を推奨する理由**

c は URI を戻す確実性が担保できないため、停止中に第三者へ到達しうる状態を残す。これは論点3で明確に避けると決めた事象であり、構成の少なさと引き換えにできない。

b は停止処理が 1 単位になる点で a より堅いが、Lambda の実装・deploy・ランタイム保守という別種の作業が増える。a で分かれる 2 つの schedule は、どちらも冪等な操作であり、片方が失敗しても手動の停止 script で同じ操作をやり直せる。動作確認環境の規模に対して、Lambda を導入する重さが見合わないと判断した。

**API Gateway の route 形式**

path をそのまま backend へ渡すため、route は `ANY /{proxy+}` とし、integration URI に `{proxy}` を含める。`POST /graphql` が `http://<ip>:18101/graphql` へ転送される。

#### 提案0へのフィードバック

**結果:** 起動管理の方式は a を採用。ただし提案0が「三案に共通の前提」として提示した standalone task（`RunTask`）の採用は、選択肢として示されておらず合意されていないと指摘された。

> 起動管理についてはa。でも、runtaskにするかは合意してない

指摘のとおり、`RunTask` を使うか ECS service の `desiredCount` を切り替えるかは独立した decision であり、提案0はこれを前提へ埋め込んで選択の機会を出していなかった。

加えて、埋め込む際に書いた理由自体が誤っていた。「service は task が終了すると自動で再起動するため 30 分で落とす運用と競合する」と述べたが、これが成立するのは案 c（task が自分で終了する）の場合だけである。案 a は外部から停止するため、service であっても `desiredCount` を 0 にすれば再起動は起きない。

この decision は論点7へ分離する。論点6の決定は起動管理の方式に限る。両者が独立して決められるのは、案 a の構造（ローカル script が AWS CLI を叩き、EventBridge Scheduler が AWS API を直接呼ぶ）が、停止操作の中身が `ecs:StopTask` でも `ecs:UpdateService` でも変わらないためである。

### 決定

起動・停止の操作と自動停止を次の形で行う。実行対象が `RunTask` か ECS service かは論点7で決める。

**操作の実体**

- 起動・停止は、開発者の手元で実行するローカル script（`scripts/review_backend/start.sh`、`scripts/review_backend/stop.sh`）が AWS CLI を叩いて行う。
- 起動 script は、task を起動し、RUNNING になるまで待ち、ENI から public IP を取得し、API Gateway の integration URI を `http://<public IP>:18101/{proxy}` へ更新し、自動停止の schedule を作り、到達 URL と自動停止の予定時刻を出力する。
- 停止 script は、停止に必要な操作を即座に実行し、自動停止の schedule を削除する。

**自動停止**

- EventBridge Scheduler の one-time schedule を 30 分後に 2 つ作る。Lambda を経由せず AWS API を直接呼ぶ（universal target）。
  - task を終了させる schedule
  - integration URI を到達しない値（`http://192.0.2.1:18101/{proxy}`）へ戻す schedule
- schedule は `ActionAfterCompletion: DELETE` とし、実行後に残さない。起動 script は、同名の schedule が既にあれば削除してから作る。
- 手動停止と自動停止で起きることを同じにする。停止は「task の終了」と「integration URI を戻す」の 2 つが揃って完了する。片方だけが成功した場合は、どちらも冪等であるため停止 script を実行し直せば揃う。

**Lambda を導入しない理由**

停止処理を 1 つの Lambda にまとめれば、2 つの schedule の片方だけが成功する状態は消える。しかし Lambda の実装、deploy 経路、ランタイム保守という別種の作業が増える。2 つの操作がいずれも冪等で、失敗しても停止 script で回復できることに対して、この規模では見合わないと判断した。

**API Gateway の route 形式**

path をそのまま backend へ渡すため、route は `ANY /{proxy+}` とし、integration URI に `{proxy}` を含める。`POST /graphql` が `http://<ip>:18101/graphql` へ転送される。

## 論点7: task を `RunTask` で起動するか、ECS service の `desiredCount` で制御するか

**ステータス:** 決定

**親論点:** 論点6

**種別:** TBDヒアリング

### イテレーション0: 起動単位を決める

#### 提案0

**推奨:** a。起動に失敗したとき、原因が残った状態で止まり、リトライが繰り返されないため。

##### a. `RunTask` で standalone task として起動する

- 起動: `aws ecs run-task`。停止: `aws ecs stop-task --task <task ARN>`。
- Terraform が持つのは cluster と task definition だけで、「起動中かどうか」の状態を持つ resource がない。
- 起動が失敗した場合（image pull 失敗、migration 失敗、DB 接続失敗）、task は 1 回停止してそれで終わる。原因を確認してから直し、もう一度起動する。
- 停止 script は task ARN を知る必要があるが、`aws ecs list-tasks --cluster <cluster> --family <task definition family>` で特定できる。起動時に ARN を手元へ保存しておく必要はない。
- 「今起動しているか」は task の存在そのもので表される。

##### b. ECS service を作り、`desiredCount` を 0 と 1 で切り替える

- 起動: `aws ecs update-service --desired-count 1`。停止: `--desired-count 0`。固定の service 名だけで操作でき、task ARN を扱わない。
- `desiredCount` が 0 の間は task が存在しないため、課金は発生しない。
- 起動が失敗した場合、service は task を再作成し続ける。migration の失敗や DB 接続の失敗が解消されない限り、CloudWatch Logs へ同じ失敗が積み上がり、どの試行のログを見ているかが分かりにくくなる。
- Terraform が `aws_ecs_service` を持つ。`desiredCount` は運用中に script が変えるため、Terraform 側では `lifecycle { ignore_changes = [desired_count] }` が要る。これがないと `terraform apply` のたびに停止中の環境が起動されたり、起動中の環境が停止されたりする。
- public IP を取るには、結局 `list-tasks` から task を特定して ENI を引く必要があり、a と同じ手数になる。

#### 提案背景

**この decision を分離した理由**

論点6の提案0は `RunTask` を前提として提示し、選択肢にしていなかった。起動管理の方式（ローカル script + EventBridge Scheduler）と、起動単位（standalone task か service か）は独立して決められる。停止操作が `ecs:StopTask` になるか `ecs:UpdateService` になるかが変わるだけで、script と schedule の構造は変わらない。

**先に述べた理由の訂正**

論点6では「service は task が終了すると自動で再起動するため、30 分で落とす運用と競合する」と述べたが、これは正しくない。案 a は外部から停止するため、`desiredCount` を 0 にすれば task は再作成されない。競合が起きるのは、task が自分で終了する案 c を採った場合だけである。

**判断軸になるのは起動失敗時の挙動**

両案とも、停止中の課金はゼロであり、public IP を取得する手数も同じである。実際に差が出るのは、起動に失敗したときにどうなるかである。

この環境は `main` へ入る前のコードを載せる場所であり、migration の失敗や接続設定の誤りは起こりうる。service は失敗した task を再作成し続けるため、原因を確認している間にもログが積み上がる。standalone task は 1 回で止まるため、失敗した試行のログがそのまま残り、原因を確認してから起動し直せる。

service の利点である自動復旧は、落ちたら困る環境で効く。30 分で意図的に落とす環境では、その利点が働く場面がない。

#### 提案0へのフィードバック

**結果:** b を採用。ただし提案0が b の弱点として挙げた `lifecycle { ignore_changes = [desired_count] }` は、`desired_count = 0` を定義の正とすることで不要になると指摘された。

> じゃあ、bで、desired_countが0前提でterraform立てて、eventbridgeだけが増減を管理すればいいんじゃないか？

「EventBridge だけが増減を管理する」の範囲を確認したところ、起動側（0 → 1）は論点6の決定どおりローカル script が担い、Terraform が実行時の増減に関与しないという意味であることを確認した。

提案0は b の利点を一つ挙げ損ねていた。停止 schedule の内容が固定になる点である。`RunTask` では停止 schedule に task ARN を埋める必要があり、ARN は起動のたびに変わるため schedule を毎回作り直すことになる。service なら停止 schedule は「service 名 + `desiredCount` 0」で固定され、起動のたびに変わるのは実行時刻だけになる。

### 決定

ECS service を作り、`desired_count` を 0 と 1 で切り替える形にする。

**Terraform と実行時状態の分担**

- Terraform の定義は `desired_count = 0` とする。`lifecycle { ignore_changes = [desired_count] }` は付けない。
- この結果、`terraform apply` は「停止状態へ戻す」操作になる。起動中に apply すれば環境は落ちる。定義と実態がずれたまま放置されるより、apply が常に停止側へ倒れるほうが安全であるため、この挙動を意図したものとして扱う。
- 実行時の増減は Terraform が関与しない。起動 script が 0 → 1、停止 script と EventBridge Scheduler が 1 → 0 を行う。

**停止 schedule**

停止 schedule の target は `aws-sdk:ecs:updateService`（`desiredCount` を 0 にする）とし、内容は固定になる。integration URI を戻す schedule と合わせて 2 つを 30 分後に作る点は論点6の決定のままとする。

**起動失敗時の扱い**

service は起動に失敗した task を再作成し続ける。これに対して deployment circuit breaker を入れる選択肢があるが、今回は入れない。

- 30 分後に `desiredCount` が 0 になるため、再作成は無限には続かず最大 30 分で止まる。
- 起動失敗に気づいた開発者は、待たずに停止 script を実行できる。
- circuit breaker の rollback が `desired_count` 変更による deployment に対してどう振る舞うかは実測しなければ確定せず、それを確定させるコストが、失敗ログの積み上がりを抑える利益に見合わない。

この判断により、起動が失敗したときは「同じ失敗が最大 30 分ぶん CloudWatch Logs へ積み上がる」ことを受け入れる。

## 論点8: review 環境の Terraform をどこへ置き、state をどう分けるか

**ステータス:** 決定

**親論点:** 論点1

**種別:** TBDヒアリング

### イテレーション0: Terraform の配置、state の分離、ECS cluster の扱いを決める

#### 提案0

**推奨:** b。`desired_count = 0` を定義の正とする決定（論点7）と、prod の変更が review 環境を巻き込まない構造を両立できるため。

##### a. 既存の `infrastructure/terraform/envs/prod` から backend の review module を呼ぶ

state は既存の `prod/terraform.tfstate` を共有する。init と apply の手順が増えない。

一方で、review 環境の resource を変えるための `terraform apply` が prod 全体を対象にする。plan には毎回 frontend の prod resource が並び、review のための適用が prod へ波及する余地を残す。

論点7で `desired_count = 0` を定義の正としたため、prod の変更のために apply すると、その時点で起動中の review 環境が落ちる。安全側の挙動ではあるが、review 環境を使っている間は prod 側の apply ができないという制約になる。

##### b. `infrastructure/terraform/envs/review/` を新設し、review 専用の state を持つ

```text
infrastructure/terraform/envs/
├── prod/          # 既存。state key = prod/terraform.tfstate
│   └── main.tf    # state_in_s3 と frontend module を呼ぶ
└── review/        # 新設。state key = review/terraform.tfstate
    ├── main.tf    # backend/terraform/envs/review を module として呼ぶ
    ├── init_terraform.sh
    └── apply_terraform.sh

backend/terraform/          # 新設
├── values/values.tf        # appname = "nanitabe-back"
├── modules/
│   ├── ecr/
│   ├── ecs/                # cluster、task definition、service（desired_count = 0）
│   ├── apigateway/         # HTTP API、custom domain、ACM 証明書、Route53
│   └── cicd/               # CodePipeline + CodeBuild
└── envs/review/main.tf     # stage = "review" を local で持ち、各 module へ配る
```

- prod と review が別 state になり、review の apply が prod の resource を対象にしない。
- `frontend/terraform/envs/review/`（現在 `.gitkeep` だけの空 directory）と整合する。将来 frontend の review 環境を作るとき、同じ `infrastructure/terraform/envs/review/main.tf` から module として呼べる。
- 既存の構造（`infrastructure/terraform/envs/*` が root、各アプリの `terraform/envs/*` が module）を崩さない。
- init と apply の script は既存 prod と同型のものを `envs/review/` へ置く。`init_terraform.sh` の `TF_ENV` が `review` になる。

##### c. `backend/terraform/envs/review` 自体を root module にする

`infrastructure/` を経由せず、backend の directory から直接 apply する。

階層が浅くなる一方、既存の「`infrastructure/terraform/envs/*` が root」という構造から外れる。`frontend/terraform/envs/review/` の器も同じ扱いにするのか、frontend だけ `infrastructure` 経由のままにするのかという不整合が生じる。

**ECS cluster について（三案に共通ではない。b を選んだ場合の前提）**

既存の cluster は別プロジェクトのものであり、流用しない。`nanitabe-back-review` の cluster を新設する。Fargate だけを使う cluster に固定費は発生しないため、分けることによる課金の増加はない。

#### 提案背景

**この論点で決めること**

論点1から論点7で、何を作るかは確定した。残るのは、それらの Terraform 定義をどこへ置き、どの state で管理するかである。state の分け方は、apply の影響範囲と、review 環境を使っている間に何ができなくなるかを決める。

**state を分ける判断の根拠**

論点7で `desired_count = 0` を定義の正とし、`terraform apply` が停止側へ倒れる挙動を意図したものとして受け入れた。この決定は「apply が review 環境を落とす」ことを前提にしている。

同じ state に prod が同居していると、この前提が prod 側の作業にも波及する。frontend の prod resource を変えるための apply が、起動中の review 環境を落とす。review 環境は 30 分で落ちる短命な環境なので実害は小さいが、二つの独立した作業が state を介して干渉する構造そのものを避けたい。

**既存の空 directory が示していること**

`frontend/terraform/envs/review/` は `.gitkeep` だけを持つ空の directory として既に存在する。review 環境を `envs/review` という単位で持つ意図が、frontend 側で先に置かれている。backend も同じ単位を採り、root を `infrastructure/terraform/envs/review/` に置けば、将来 frontend の review 環境を足すときに同じ root から呼べる。

#### 提案0へのフィードバック

**結果:** 受諾。

> b

### 決定

review 環境の Terraform を次の配置にする。

```text
infrastructure/terraform/envs/
├── prod/          # 既存。state key = prod/terraform.tfstate
└── review/        # 新設。state key = review/terraform.tfstate
    ├── main.tf    # backend/terraform/envs/review を module として呼ぶ
    ├── init_terraform.sh
    └── apply_terraform.sh

backend/terraform/          # 新設
├── values/values.tf        # appname = "nanitabe-back"
├── modules/
│   ├── ecr/
│   ├── ecs/                # cluster、task definition、service（desired_count = 0）
│   ├── apigateway/         # HTTP API、custom domain、ACM 証明書、Route53
│   └── cicd/               # CodePipeline + CodeBuild
└── envs/review/main.tf     # stage = "review" を local で持ち、各 module へ配る
```

- prod と review を別 state にする。論点7で `terraform apply` が停止側へ倒れる挙動を受け入れたため、同じ state に prod が同居していると、prod 側の変更のための apply が起動中の review 環境を落とす。二つの独立した作業が state を介して干渉する構造を避ける。
- root は `infrastructure/terraform/envs/*` に置き、各アプリの `terraform/envs/*` を module として呼ぶ既存構造を維持する。`frontend/terraform/envs/review/`（現在 `.gitkeep` だけの空 directory）を将来同じ root から呼べる。
- init と apply の script は既存 prod と同型のものを `envs/review/` へ置く。`init_terraform.sh` の `TF_ENV` を `review` にする。
- ECS cluster は `nanitabe-back-review` を新設する。既存の cluster は別プロジェクトのものであり流用しない。Fargate だけを使う cluster に固定費は発生しない。

## 論点9: DB 接続情報と `RAILS_MASTER_KEY` を task へどう渡すか

**ステータス:** 決定

**親論点:** 論点1

**種別:** TBDヒアリング

### イテレーション0: secret の保管先と、Terraform が関与する範囲を決める

#### 提案0

**推奨:** b。apply 一回で環境が揃い、task definition と ECS console に平文を残さないため。

##### a. task definition の `environment` へ平文で書く

`apply_terraform.sh` が `.env` から読んだ値を `TF_VAR_*` 経由で渡し、task definition の `environment` へそのまま入れる。

追加の resource が要らない。一方で、`DB_PASS` と `RAILS_MASTER_KEY` が task definition の定義として残り、ECS console の task definition 画面や `describe-task-definition` の出力に平文で現れる。Terraform state にも入る。

##### b. SSM Parameter Store（SecureString）へ置き、task definition の `secrets` で参照する

`apply_terraform.sh` が `.env` から読んだ値を `TF_VAR_*` 経由で渡し、Terraform が `aws_ssm_parameter`（`type = "SecureString"`）を作る。task definition では `environment` ではなく `secrets` で parameter の ARN を参照する。

- task definition には parameter の ARN だけが載り、値は載らない。ECS console や `describe-task-definition` から値が見えない。
- task execution role に `ssm:GetParameters` と、SecureString を復号するための `kms:Decrypt` が要る。
- SSM Parameter Store の Standard parameter は無料。AWS managed key で暗号化する限り KMS の課金も発生しない。停止中課金ゼロの要件（論点1）を満たす。
- Terraform state には値が入る。state は S3 に暗号化して置かれ、アクセスできるのは同じ AWS credentials を持つ人に限られる。その人は `.env` にも到達できるため、state へ値が入ることによる実質的な露出の増加は小さい。

##### c. SSM Parameter Store へ手動で登録し、Terraform は `data` source で参照する

Terraform state に値が入らない。

一方で、parameter を誰がいつ登録するかという手順が Terraform の外に生まれる。初回セットアップと値の更新が手作業になり、「parameter が未登録でも apply は通るが task が起動しない」という失敗モードが増える。

**Secrets Manager を使わない理由**

Secrets Manager は secret あたり月 $0.4 の固定課金が発生する。停止中課金ゼロの要件に抵触するため、三案のいずれでも使わない。

#### 提案背景

**既存の扱いと、その TODO**

`frontend/terraform/modules/cicd/codebuild/main.tf` の 3 行目に `variable "aws_access_key" { type = string } # TODO: secret化する` というコメントがある。CodeBuild の `environment_variable` は type を指定しておらず、既定の `PLAINTEXT` として扱われる。既存の frontend 側は secret を平文で扱っており、それを改善対象として認識した状態にある。

今回の backend review 環境は新規に作るため、この TODO と同じ方向（平文を避ける形）で最初から作れる。既存 frontend 側の修正は今回の scope 外とし、backend 側が先に型を作る位置づけにする。

**保管先を SSM Parameter Store にする理由**

ECS の task definition が `secrets` として参照できるのは SSM Parameter Store と Secrets Manager の二つである。Secrets Manager は固定課金があるため、停止中課金ゼロの要件で除外される。SSM Parameter Store の Standard parameter は無料で、AWS managed key による暗号化にも課金がない。

**b と c の差**

両者の違いは、Terraform state に値を入れるかと、parameter の登録を誰が行うかである。

c は state から値を排除できるが、その代わりに Terraform の外で管理する手順が生まれる。この環境は「起動 script を叩けば使える」ことを目指しており、初回セットアップに Terraform 外の手作業を増やすと、運用 document に書く手順が増え、忘れたときの失敗が分かりにくくなる（apply は成功するのに task だけが起動しない）。

b の state への露出は、state へアクセスできる人が `.env` にも到達できる以上、新しい露出面を作らない。

#### 提案0へのフィードバック

**結果:** 受諾。

> b

### 決定

`DB_NAME` / `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASS` / `RAILS_MASTER_KEY` を SSM Parameter Store の SecureString として保管し、task definition の `secrets` で参照する。

- `apply_terraform.sh` が `.env` から読んだ値を `TF_VAR_*` 経由で渡し、Terraform が `aws_ssm_parameter`（`type = "SecureString"`）を作る。既存 prod の apply script と同じ型を踏襲する。
- task definition は `environment` ではなく `secrets` で parameter の ARN を参照する。task definition と `describe-task-definition` の出力に値が現れない。
- task execution role へ `ssm:GetParameters` と `kms:Decrypt` を与える。
- Standard parameter と AWS managed key による暗号化はいずれも無料であり、停止中課金ゼロの要件（論点1）を満たす。
- Secrets Manager は secret あたり月 $0.4 の固定課金があるため使わない。
- Terraform state には値が入る。state は S3 に暗号化して置かれ、到達できる人は `.env` にも到達できるため、新しい露出面を作らない。

`RAILS_ENV` / `RAILS_LOG_TO_STDOUT` / `PORT` / `BACKEND_PROD_HOST` は secret ではないため、`environment` に平文で置く。

既存 frontend 側（`frontend/terraform/modules/cicd/codebuild/main.tf` の `# TODO: secret化する`）の修正は今回の scope 外とする。backend review 環境が先に型を作る位置づけにする。

## 論点10: 運用 document をどこへ置き、AI agent がどこまで確認なしで実行してよいか

**ステータス:** 決定

**親論点:** 論点1

**種別:** TBDヒアリング

### イテレーション0: document の配置と、実行者の線引きを決める

#### 提案0

**推奨:** a。Terraform 側に README が一つも存在しない現状で新設すると、その一つだけが動線のない場所に孤立するため。

##### a. `backend/docs/ai_guideline/development_standard/review_environment.md` の 1 ファイルへ集約する

既存の `docker.md`、`testing.md`、`formatting.md`、`application_architecture.md` と同階層に置く。`AGENTS.md` → `backend/CLAUDE.md` → `backend/docs/ai_guideline/README.md` → `development_standard/README.md` という既存の動線にそのまま乗る。

扱う内容:

- review 環境とは何か（backend API 単体、開発者の PC 以外の端末から叩くためのもの、frontend は繋がない）
- 使い方（`main` へ rebase → `review` branch へ force push → build の成否を確認 → 起動 script → URL を叩く → 停止 script）
- 規約（`review` branch に何が載っているかは保証しない。開く前に自分で載せる。後始末はしない）
- 開発 DB を共有していること（migration と mutation が開発 DB へ届く）
- Terraform の制約（`desired_count = 0` が定義の正であり、`terraform apply` は起動中の環境を落とす。state は prod と分かれている）
- review 環境に閉じる操作の定義と、閉じる範囲で緩める扱い・緩めない扱い
- 誤適用（frontend と繋ぐ用途に使う、`admin/` 配下の画面を開こうとする）

##### b. 使い方と Terraform の制約を別ファイルへ分ける

参照元 steering と同じ形。使い方を `backend/docs/ai_guideline/development_standard/review_environment.md` へ、Terraform 側の制約を `infrastructure/terraform/envs/review/README.md` へ置く。

読者が違うため owner を分けられる。一方、nanitabe の `infrastructure/` と `*/terraform/` の配下には現在 README が一つも存在せず、`AGENTS.md` からの動線もない。新設した README が読まれない場所に置かれる。

##### c. `infrastructure/` 側へ集約する

review 環境は infrastructure の話であるという整理。ただし b と同じく動線の問題を持ち、さらに「動作確認したい開発者」が最初に見る場所から外れる。

**AI agent が確認なしで実行してよい範囲（a を選んだ場合、上記 document へ記載する内容）**

review 環境に閉じる操作を、次のいずれにも影響が及ばない操作と定義する。

- 本番 backend とその host
- 開発 DB のスキーマとデータ
- prod の Terraform state と、そこにある resource
- `.env` の内容と SSM parameter の値

閉じる操作に該当するのは、`review` branch への force push、起動 script の実行、停止 script の実行、review state に対する `terraform plan`、および差分が review state 内の resource の追加・変更だけで destroy を含まない `terraform apply` である。これらは操作ごとの事前確認なしに実行してよい。失敗しても停止 script と再実行で回復でき、影響が review 環境の外へ出ないためである。

閉じる範囲でも緩めない扱いを三つ置く。

- `terraform apply` の前に必ず `terraform plan` を実行し、差分が定義の条件を満たすことを確認する。満たさない差分が 1 件でもあれば apply せず停止して報告する。
- secret を log、成果物、chat へ出さない。
- `main` への merge と PR 操作は緩和の対象外とする。

閉じる操作に見えて該当しないものを挙げる。`review` branch へ載せたコードに migration が含まれる場合、その migration は開発 DB のスキーマを変えるため閉じない。prod state に対する apply は、review 環境のための変更であっても閉じない。SSM parameter の値を変えることは、値の出所が `.env` であり開発環境と共有されているため閉じない。

#### 提案背景

**この論点で決めること**

論点1から論点9で、何を作りどう動かすかが確定した。残るのは、それを次に使う人が議論ログを読まずに辿れる場所へ置くことと、AI agent がどこまで自走してよいかの線引きである。

**参照元と判断が分かれる理由**

参照元 steering は、使い方を開発者向け document へ新設し、infrastructure 側の制約を既存の Terraform README へ追記した。読者が Terraform を読まない開発者であり、Terraform 側 README の動線から外れるという理由で分けている。

この判断は、参照元に Terraform 側の README が既に存在し、Terraform を触る人がそこを読む習慣があったことを前提にしている。nanitabe では `infrastructure/` と各アプリの `terraform/` 配下に README が一つも無く、`AGENTS.md` にも `infrastructure/` への言及がない。分ける先が「既にある読まれる場所」ではなく「新設する読まれない場所」になるため、同じ形を採ると制約が読まれないまま残る。

**Terraform の制約を使い方と同じ場所へ置く理由**

`terraform apply` が起動中の review 環境を落とすという制約（論点7、論点8）は、Terraform を触る人だけでなく、review 環境を使っている開発者にとっても知る必要がある事実である。「さっきまで動いていたのに落ちた」という事象の原因になる。読者が重なるため、同じ場所にある利点がある。

**実行者の線引きを document へ書く理由**

この線引きは、次に AI agent へ作業を依頼する人が、毎回ゼロから判断しないために要る。参照元では「軽微だから閉じている」という解釈の余地を残さないよう、判定を `terraform plan` の出力から機械的に行える形にした。今回も同じ方針を採り、閉じるかどうかを対象 resource と state で決める。`review` という名前が付いているかでは決めない。

#### 提案0へのフィードバック

**結果:** b を採用。提案0が b を却下した理由（Terraform 側に README が無く動線もない）が、却下の理由になっていないと指摘された。

> b。読まれるようにすればいいだけじゃん

提案0は「動線がないから読まれない」を b の欠点として扱ったが、動線は今回の作業で作れる。現状の欠陥を、変えられない前提として扱っていた。動線が無いことは b を選ばない理由ではなく、b を選んだときに一緒に作るものである。

AI agent の実行範囲の定義そのものへの異議はなかったため、内容は維持し、置き場所だけを b の形へ変える。

### イテレーション1: 分割後の配置と、Terraform 側 document への動線を確定する

#### 提案1

**配置**

```text
AGENTS.md                                   # 既存。infrastructure/ の行を足す
infrastructure/README.md                    # 新設。infrastructure の入口
backend/docs/ai_guideline/development_standard/
└── review_environment.md                   # 新設。使い方・規約・実行者の線引き
```

**動線の作り方**

`AGENTS.md` は現在 `backend/` と `frontend/` だけを列挙しており、`infrastructure/` に触れていない。ここへ 1 行足し、`infrastructure/README.md` を入口にする。今回 `infrastructure/terraform/envs/review/` と `backend/terraform/` を新設するため、この追記は今回の変更に伴うものとして自然に収まる。

`infrastructure/README.md` は infrastructure 配下の索引として、次を扱う。

- `terraform/envs/prod` と `terraform/envs/review` が別 state であること（state key と、どちらに何があるか）
- `init_terraform.sh` と `apply_terraform.sh` の使い方（既存 prod の script と同型であること）
- review 環境の Terraform 制約: `desired_count = 0` が定義の正であり、`terraform apply` は起動中の review 環境を落とす
- 実行時の `desired_count` と integration URI は Terraform が管理せず、起動・停止 script と EventBridge Scheduler が持つこと

`backend/docs/ai_guideline/development_standard/review_environment.md` は、動作確認したい開発者を読者として、次を扱う。

- review 環境とは何か（backend API 単体、PC 以外の端末から叩くためのもの、frontend は繋がない）
- 使い方（`main` へ rebase → `review` branch へ force push → build の成否を確認 → 起動 script → URL を叩く → 停止 script）
- 規約（`review` branch に何が載っているかは保証しない。開く前に自分で載せる。後始末はしない）
- 開発 DB を共有していること（migration と mutation が開発 DB へ届く）
- review 環境に閉じる操作の定義と、閉じる範囲で緩める扱い・緩めない扱い
- 誤適用（frontend と繋ぐ用途に使う、`admin/` 配下の画面を開こうとする）

**二つの document の関係**

`terraform apply` が起動中の環境を落とす事実は、Terraform を触る人と、環境を使っている開発者の両方に関係する。制約の本文は `infrastructure/README.md` が持ち、`review_environment.md` からは「起動中に `terraform apply` を実行すると環境が落ちる」という利用者から見た帰結だけを書いて参照する。同じ条件を二箇所へ書くと、片方だけが更新されたときに矛盾する。

`infrastructure/terraform/envs/review/README.md` は作らない。infrastructure 配下の README を 2 階層に分けても、現時点で書き分ける内容が `infrastructure/README.md` の review の節に収まる量しかない。将来 frontend の review 環境が加わり、環境ごとの固有制約が増えた時点で分割を検討する。

#### 提案背景

b を採用したことで決めるべきことが二つ生じた。分割後の配置と、Terraform 側 document を読まれる場所にするための動線である。

動線は `AGENTS.md` に `infrastructure/` の行を足し、`infrastructure/README.md` を入口にすることで作る。`AGENTS.md` は既に `backend/` と `frontend/` について「詳細な指示は各 CLAUDE.md」という形の索引になっているため、同じ形で `infrastructure/` を足せる。

配置を二つに留め、`infrastructure/terraform/envs/review/README.md` を作らないのは、今回書く内容が階層を分けるほどの量にならないためである。読み手が辿る階層を増やすと、その各段で「ここに書いてあるのか、さらに下か」を判断させることになる。

#### 提案1へのフィードバック

**結果:** 受諾。

> ok

### 決定

運用 document を二つに分け、Terraform 側へ動線を作る。

**配置**

```text
AGENTS.md                                   # 既存。infrastructure/ の行を足す
infrastructure/README.md                    # 新設。infrastructure の入口
backend/docs/ai_guideline/development_standard/
└── review_environment.md                   # 新設。使い方・規約・実行者の線引き
```

**動線**

`AGENTS.md` は現在 `backend/` と `frontend/` だけを列挙している。ここへ `infrastructure/` の行を足し、`infrastructure/README.md` を入口にする。今回 `infrastructure/terraform/envs/review/` と `backend/terraform/` を新設するため、この追記は今回の変更に伴うものとして収まる。

**書き分け**

`infrastructure/README.md`（読者: Terraform を適用する人）

- `terraform/envs/prod` と `terraform/envs/review` が別 state であること。state key と、どちらに何があるか
- `init_terraform.sh` と `apply_terraform.sh` の使い方。既存 prod の script と同型であること
- `desired_count = 0` が定義の正であり、`terraform apply` は起動中の review 環境を落とすこと
- 実行時の `desired_count` と integration URI を Terraform が管理せず、起動・停止 script と EventBridge Scheduler が持つこと

`backend/docs/ai_guideline/development_standard/review_environment.md`（読者: 動作確認したい開発者）

- review 環境とは何か。backend API 単体であり、PC 以外の端末から叩くためのもので、frontend は繋がないこと
- 使い方。`main` へ rebase → `review` branch へ force push → build の成否を確認 → 起動 script → URL を叩く → 停止 script
- 規約。`review` branch に何が載っているかは保証しない。開く前に自分で載せる。後始末はしない
- 開発 DB を共有しており、migration と mutation が開発 DB へ届くこと
- review 環境に閉じる操作の定義と、閉じる範囲で緩める扱い・緩めない扱い
- 誤適用。frontend と繋ぐ用途に使うこと、`admin/` 配下の画面を開こうとすること

**重複の避け方**

`terraform apply` が起動中の環境を落とす制約の本文は `infrastructure/README.md` が持つ。`review_environment.md` からは「起動中に `terraform apply` を実行すると環境が落ちる」という利用者から見た帰結だけを書いて参照する。同じ条件を二箇所へ書くと、片方だけが更新されたときに矛盾する。

**作らないもの**

`infrastructure/terraform/envs/review/README.md` は作らない。書き分ける内容が `infrastructure/README.md` の review の節に収まる量しかない。将来 frontend の review 環境が加わり、環境ごとの固有制約が増えた時点で分割を検討する。

**AI agent が確認なしで実行してよい範囲**（`review_environment.md` へ記載する）

review 環境に閉じる操作を、次のいずれにも影響が及ばない操作と定義する。

- 本番 backend とその host
- 開発 DB のスキーマとデータ
- prod の Terraform state と、そこにある resource
- `.env` の内容と SSM parameter の値

閉じる操作に該当するのは、`review` branch への force push、起動 script の実行、停止 script の実行、review state に対する `terraform plan`、および差分が review state 内の resource の追加・変更だけで destroy を含まない `terraform apply` である。これらは操作ごとの事前確認なしに実行してよい。失敗しても停止 script と再実行で回復でき、影響が review 環境の外へ出ないためである。

閉じる範囲でも緩めない扱いを三つ置く。

- `terraform apply` の前に必ず `terraform plan` を実行し、差分が定義の条件を満たすことを確認する。満たさない差分が 1 件でもあれば apply せず停止して報告する。
- secret を log、成果物、chat へ出さない。
- `main` への merge と PR 操作は緩和の対象外とする。

閉じる操作に見えて該当しないものを三つ挙げる。`review` branch へ載せたコードに migration が含まれる場合、その migration は開発 DB のスキーマを変えるため閉じない。prod state に対する apply は、review 環境のための変更であっても閉じない。SSM parameter の値を変えることは、値の出所が `.env` であり開発環境と共有されているため閉じない。

閉じるかどうかは対象 resource と state で決まり、`review` という名前が付いているかでは決まらない。

## 論点11: 完成をどう検証し、どのリスクを受け入れたまま完成とするか

**ステータス:** 決定

**親論点:** 論点1

**種別:** TBDヒアリング、認識齟齬

### イテレーション0: 受け入れ基準の検証手段、残るリスクの扱い、要件表現の訂正を決める

#### 提案0

**先に訂正すべきこと: 「停止中の課金ゼロ」は厳密には達成できない**

論点1で「停止中に課金が発生する resource を構成へ含めない」を MUST に置いた。ここまでの決定は、時間課金の resource（ALB、RDS、NAT Gateway、Elastic IP、Secrets Manager）を一つも含まない構成になっている。ただし、停止中にも課金される保存料が二つ残る。

| 対象 | 課金 | 抑え方 |
| --- | --- | --- |
| ECR の image 保存 | $0.10 / GB / 月。Rails の image は 1 GB 前後 | lifecycle policy で最新 1 世代だけ残す |
| CloudWatch Logs の保存 | $0.03 / GB / 月 | log group の retention を 7 日にする |

合計で月 $0.2 程度になる。要件の表現を「停止中に課金が発生する resource を構成へ含めない」から、**「停止中に発生する課金を、image と log の保存料に限る。時間課金の resource を構成へ含めない」**へ改める。

この訂正が必要なのは、元の表現のままだと受け入れ基準を満たせないためである。「ゼロ」を字義どおり検証すると失敗し、実態に合わせて基準を緩めることになる。先に表現を実態へ合わせておく。

**受け入れ基準をどう検証するか**

「停止中に時間課金の resource が無い」ことは、Cost Explorer ではなく構成で確認する。Cost Explorer への反映は翌日以降になり、動作確認の完了判定に使えない。`terraform plan` と `terraform state list` の出力に、ALB、RDS、NAT Gateway、Elastic IP、Secrets Manager の resource が含まれないことを確認する形にする。

**自動停止が働かなかった場合の検知**

自動停止が失敗すると、task が動き続ける。0.25 vCPU / 0.5 GB の Fargate task を止め忘れると月 $8.6 程度になり、放置すると効いてくる。

検知の手段として CloudWatch alarm で running task count を監視する案があるが、alarm は 1 つあたり月 $0.10 の常時課金が発生する。上で訂正した要件（時間課金の resource を含めない）に抵触する。

代わりに、起動 script が実行時に「既に `desired_count` が 1 なら、その task がいつから起動しているか」を表示する。止め忘れたまま次に起動しようとしたときに、必ず気づく。自動停止の失敗そのものを監視する仕組みは作らない。

**追加の保護を設けない**

URL を知る第三者が GraphQL endpoint へ到達できる点について、Basic authentication 等の追加保護は設けない。認証は devise + devise-jwt のみとする。

本番 backend も同じ GraphQL endpoint を公開しており、review 環境だけに追加の保護を設ける理由がない。API Gateway で Basic authentication を実現するには Lambda authorizer が要り、論点6で Lambda を導入しないと決めた判断とも整合しない。

受け入れるリスクは、`main` へ未マージのコードが動くため、未検証の脆弱性が一時的に露出しうることである。環境が起動しているのは最大 30 分であり、リスクの窓は短い。

**テスト方針**

| 検証すること | 手段 |
| --- | --- |
| 構成に時間課金の resource が無い | `terraform plan` の出力に ALB / RDS / NAT Gateway / Elastic IP / Secrets Manager が現れないことを確認する |
| 起動 script で到達できるようになる | 起動 script を実行し、`https://review-backend-nanitabe.<hosted zone>/graphql` へ `POST` して応答を得る |
| PC 以外の端末から到達できる | スマホから同じ URL を叩く。これが今回の主目的であり、代替手段で確認したことにしない |
| IP 直アクセスが弾かれる | task の public IP へ直接 `POST` し、403 が返ることを確認する |
| 停止 script で到達できなくなる | 停止 script を実行し、同じ URL が応答しなくなることを確認する |
| 30 分で自動停止する | 起動後に停止操作をせず 30 分待ち、到達できなくなることと `desired_count` が 0 になっていることを確認する |
| migration が流れる | 起動時の log に migration の実行が現れることを CloudWatch Logs で確認する |

30 分の自動停止は待ち時間が発生するが、要件の中心であるため 1 回は実測する。schedule の実行時刻を短く設定して代用すると、実際に使う 30 分の設定を検証しないまま完成にすることになる。

#### 提案背景

**この論点で決めること**

論点1から論点10で作るものが確定した。残るのは、何をもって完成とするかと、完成時点で残るリスクをどう扱うかである。design.md の受け入れ基準、リスク表、テスト方針に残っている TBD がこれに対応する。

**要件表現の訂正を独立した項目として出す理由**

「停止中の課金ゼロ」は論点1で MUST として置き、論点3で ALB を退け、論点6で Lambda を退け、論点9で Secrets Manager を退ける根拠になった。この要件自体は有効に働いている。

一方で、ECR と CloudWatch Logs の保存料は、ここまでの提案で一度も触れていなかった。要件を字義どおり検証すると満たせないため、検証の段階で基準を緩めることになる。基準を後から緩めるより、要件の表現を実態に合わせるほうが、この要件が何を禁じているのか（時間課金の resource）を正確に残せる。

#### 提案0へのフィードバック

**結果:** 提案0の内容は受諾。ただし CloudWatch alarm を課金を理由に退けた判断が覆された。

> okだし、その料金ならCloudWatch alarm入れていいよ。失敗していたときのほうが金かかるんだから

提案0は「時間課金の resource を含めない」という要件を機械的に当てて alarm を退けたが、費用対効果を見ていなかった。alarm 1 つの月 $0.10 に対し、止め忘れた task は月 $8.6 になる。要件の目的は無駄な常時課金を避けることであり、$0.10 で $8.6 のリスクを消すのは目的に沿う。

### イテレーション1: alarm の具体形と、保存料を抑える設定を確定する

#### 提案1

**alarm が使える metric の制約**

ECS の標準 metric（`AWS/ECS` namespace）は `CPUUtilization` と `MemoryUtilization` だけで、起動している task の数を直接表す metric は無い。`RunningTaskCount` は Container Insights を有効にすると得られるが、Container Insights は観測する metric 数に応じた課金があり、月 $0.10 では収まらない。

そのため、task が動いているかどうかを `CPUUtilization` の data point の有無で判定する。task が 0 なら data point が欠損する。

| 項目 | 値 |
| --- | --- |
| metric | `AWS/ECS` の `CPUUtilization`（dimension は `ClusterName` と `ServiceName`） |
| statistic | `SampleCount`（data point が存在するかを見る） |
| period | 300 秒 |
| evaluation periods | 9（合計 45 分） |
| 条件 | 9 期間すべてで data point が存在する |
| `treat_missing_data` | `notBreaching`（task が無い＝正常） |
| action | SNS topic へ通知し、topic から email へ配信する |

30 分で停止するはずの環境が 45 分間動き続けていれば、自動停止が働かなかったことになる。

**alarm は止めない**

alarm は通知するだけで task を止めない。通知を受けた人が停止 script を実行する。

止める仕組み（45 分後に強制停止する保険の schedule）を代わりに置く案もあるが、採らない。保険で止まると「30 分の自動停止が働いたのか、45 分の保険で止まったのか」が利用者から区別できず、30 分という設定が守られているかの検証も濁る。失敗したことが分かる形で残し、人が止めるほうが、原因を追える。

**起動 script 側でも防ぐ**

alarm は「schedule が作られたのに実行されなかった」場合をカバーする。「schedule の作成自体が失敗した」場合は、起動 script がその場で検知する。

起動 script は schedule の作成結果を確認し、失敗したら `desired_count` を 0 へ戻し、integration URI も戻したうえでエラー終了する。自動停止の保証がない状態で起動したままにしない。

**保存料を抑える設定**

| 対象 | 設定 |
| --- | --- |
| ECR | lifecycle policy で、最新 1 世代を残して古い image を削除する |
| CloudWatch Logs（task） | log group の retention を 7 日にする |
| CloudWatch Logs（API Gateway access log） | 同じく 7 日にする |

**訂正後の要件表現**

「停止中に発生する課金を、image と log の保存料、および止め忘れを検知する alarm に限る。時間課金の compute / network resource（ALB、RDS、NAT Gateway、Elastic IP）と Secrets Manager を構成へ含めない」とする。

停止中の課金は、ECR の image 保存（月 $0.1 程度）、CloudWatch Logs の保存（retention 7 日で月 $0.05 未満）、alarm 1 つ（月 $0.10）の合計で月 $0.3 程度になる。

#### 提案背景

feedback により alarm の採用が決まったため、決めるべきことが三つ生じた。alarm が何を監視するか、alarm が止めるのか通知するのか、そして要件の表現をどう改めるかである。

metric の制約は、この設計で最初に確認が要る点だった。「起動中の task 数を監視する」という素朴な形が標準 metric では取れず、Container Insights を有効にすると alarm 1 つぶんの費用に収まらない。`CPUUtilization` の data point の有無で代替することで、追加の課金なしに同じ判定ができる。

alarm を通知に留め、保険の強制停止を置かないのは、自動停止の失敗を失敗として見える形で残すためである。二重に止める仕組みを入れると、止まった事実だけが残り、30 分の設定が働いているかが確認できなくなる。

#### 提案1へのフィードバック

**結果:** log の retention 7 日は却下。metric を増やすことによる課金は、提案1の設計では発生しないという説明が必要になった。

> CloudWatchLogsは運用上ずっとログ残しておいてほしい。メトリクス増やして月数ドル増えるなら、失敗時の料金と競ってくるから要吟味

提案1は Container Insights を「使わない理由」として説明したが、alarm の説明の中に置いたため、metric を増やす方向の提案と読める書き方になっていた。提案1の alarm は標準 metric だけを使い、metric 課金は発生しない。

log の retention を 7 日にしたのは保存料を抑えるためだったが、運用上ずっと残す必要があるという判断が示された。保存料の試算をやり直す。

### イテレーション2: log の保持期間を確定し、alarm の費用対効果を数字で示す

#### 提案2

**log は無期限で保持する**

`retention_in_days` を設定せず、Never expire にする。task の log group と API Gateway の access log group の両方とも同じにする。

CloudWatch Logs の課金は取り込みと保存に分かれ、額が大きいのは取り込み側である。

| 課金対象 | 単価（ap-northeast-1） | この環境での見込み |
| --- | --- | --- |
| 取り込み | $0.76 / GB | production の `log_level = :info` で、30 分の起動 1 回あたり数 MB。月 10 回起動で 50 MB 前後 → 月 $0.04 |
| 保存 | $0.03 / GB / 月 | 上記のペースで 1 年蓄積して 600 MB → 月 $0.018 |

取り込みは起動している間にしか発生せず、停止中の課金は保存分だけになる。無期限で保持しても、停止中の課金はほぼ増えない。retention を切る理由がないため、無期限にする。

**metric は増やさない**

提案1の alarm は `AWS/ECS` namespace の `CPUUtilization` を使う。これは ECS が標準で出す metric であり、CloudWatch の metric 課金は発生しない。Container Insights は有効にしない。

参考として、Container Insights を有効にした場合の額を示す。従来版は custom metric として課金され、metric あたり月 $0.30、service あたり 10 から 20 個の metric が出るため月 $3 から $6 になる。これは止め忘れ時の損失と競る水準であり、採らない。enhanced observability 版は observed task-hour による従量課金で停止中はゼロになるが、標準 metric で同じ判定ができる以上、導入する理由がない。

**alarm の費用対効果**

alarm 1 つの課金は月 $0.10、年額 $1.2 である。

止め忘れた場合の損失は、0.25 vCPU / 0.5 GB の Fargate task で $0.012 / 時間になる。

| 気づくまでの期間 | 損失 |
| --- | --- |
| 1 日 | $0.29 |
| 3 日 | $0.86 |
| 1 週間 | $2.0 |
| 1 か月 | $8.6 |

alarm が無い場合、止め忘れに気づくのは次に起動しようとしたときである。起動 script が「既に起動中である」ことを表示するため、その時点では必ず気づく。使用頻度が週 1 回なら数日、月 1 回なら数週間の幅がある。

年 1 回から 2 回、数日規模の止め忘れが起きるなら、alarm の年額 $1.2 と釣り合う。使用頻度が低いほど気づくまでが長くなり、alarm の価値が上がる。

**停止中の課金の合計**

| 対象 | 月額 |
| --- | --- |
| ECR の image 保存（lifecycle policy で最新 1 世代） | $0.1 |
| CloudWatch Logs の保存（無期限、1 年蓄積時点） | $0.02 |
| CloudWatch alarm 1 つ | $0.10 |
| 合計 | $0.22 |

**訂正後の要件表現**

「停止中に発生する課金を、image と log の保存料、および止め忘れを検知する alarm に限り、合計で月 $1 を超えない。時間課金の compute / network resource（ALB、RDS、NAT Gateway、Elastic IP）と Secrets Manager、および Container Insights を構成へ含めない」とする。

金額の上限を要件へ含めるのは、「時間課金の resource を含めない」だけでは、今回の alarm のように少額で価値のある resource を機械的に退けてしまうためである。提案0で alarm を退けたのがその失敗にあたる。

#### 提案背景

feedback は二つのことを指している。log を短期で捨てないことと、metric を増やす判断には費用対効果の吟味が要ることである。

log については、保存料を抑える目的で retention を切ったが、試算すると停止中の課金への寄与が月 $0.02 程度しかなく、運用上の価値と釣り合わない。無期限にする。

metric については、提案1の設計が既に標準 metric だけを使っており課金は増えない。ただし提案1は Container Insights を alarm の説明の途中で否定的に触れただけで、最終的な構成に metric 課金が含まれないことを明示していなかった。額を並べて、何を採り何を採らないかを確定させる。

要件表現へ金額の上限を入れるのは、提案0で起きた失敗（$0.10 の alarm を「時間課金の resource を含めない」という表現だけで退けた）を繰り返さないためである。禁じているのは無駄な常時課金であり、少額で損失を防ぐ resource ではない。

#### 提案2へのフィードバック

**結果:** 受諾。あわせて、金額判断そのものを document 化する論点を別に立てることになった。

> ok。落ち着いたときに、金額判断のドキュメント立てるために論点立てておこう

### 決定

**要件表現の訂正**

論点1の MUST「停止中に課金が発生する resource を構成へ含めない」を、次へ改める。

> 停止中に発生する課金を、image と log の保存料、および止め忘れを検知する alarm に限り、合計で月 $1 を超えない。時間課金の compute / network resource（ALB、RDS、NAT Gateway、Elastic IP）と Secrets Manager、および Container Insights を構成へ含めない。

金額の上限を要件へ含めるのは、「時間課金の resource を含めない」という表現だけでは、少額で損失を防ぐ resource まで機械的に退けてしまうためである。実際に提案0では、月 $0.10 の alarm をこの表現だけを根拠に退けた。禁じているのは無駄な常時課金であり、損失を防ぐ少額の resource ではない。

**停止中の課金**

| 対象 | 月額 |
| --- | --- |
| ECR の image 保存（lifecycle policy で最新 1 世代を残す） | $0.1 |
| CloudWatch Logs の保存（無期限保持、1 年蓄積時点） | $0.02 |
| CloudWatch alarm 1 つ | $0.10 |
| 合計 | $0.22 |

**log の保持**

task の log group と API Gateway の access log group は、いずれも `retention_in_days` を設定せず無期限で保持する。CloudWatch Logs の課金は取り込み（$0.76 / GB）が主で、これは起動中にしか発生しない。停止中の課金は保存分（$0.03 / GB / 月）だけであり、月 10 回起動のペースで 1 年蓄積しても月 $0.02 程度にとどまる。運用上 log を残す価値と釣り合わないため、retention を切らない。

**止め忘れの検知**

CloudWatch alarm を 1 つ置く。Container Insights は有効にしない。

| 項目 | 値 |
| --- | --- |
| metric | `AWS/ECS` の `CPUUtilization`（dimension は `ClusterName` と `ServiceName`）。ECS の標準 metric であり metric 課金は発生しない |
| statistic | `SampleCount`（data point が存在するかを見る） |
| period | 300 秒 |
| evaluation periods | 9（合計 45 分） |
| 条件 | 9 期間すべてで data point が存在する |
| `treat_missing_data` | `notBreaching`（task が無い＝正常） |
| action | SNS topic へ通知し、topic から email へ配信する |

起動している task の数を直接表す標準 metric は存在せず、`RunningTaskCount` は Container Insights を要する。Container Insights の従来版は metric あたり月 $0.30、service あたり 10 から 20 個の metric が出るため月 $3 から $6 になり、止め忘れ時の損失と競う水準になる。標準 metric の data point の有無で同じ判定ができるため導入しない。

alarm は通知するだけで task を止めない。45 分後に強制停止する保険の schedule は置かない。保険で止まると「30 分の自動停止が働いたのか、45 分の保険で止まったのか」が利用者から区別できず、30 分の設定が守られているかを検証できなくなる。失敗が失敗として見える形で残し、通知を受けた人が停止 script を実行する。

「schedule の作成自体が失敗した」場合は alarm の対象外であり、起動 script がその場で検知する。起動 script は schedule の作成結果を確認し、失敗したら `desired_count` を 0 へ戻し、integration URI も戻したうえでエラー終了する。自動停止の保証がない状態で起動したままにしない。

**追加の保護を設けない**

URL を知る第三者が GraphQL endpoint へ到達できる点について、Basic authentication 等の追加保護を設けない。認証は devise + devise-jwt のみとする。本番 backend も同じ GraphQL endpoint を公開しており、review 環境だけに追加の保護を設ける理由がない。API Gateway で Basic authentication を実現するには Lambda authorizer が要り、論点6で Lambda を導入しないとした判断とも整合しない。

受け入れるリスクは、`main` へ未マージのコードが動くため未検証の脆弱性が一時的に露出しうることである。起動しているのは最大 30 分であり、リスクの窓は短い。

**受け入れ基準の検証手段**

「停止中に時間課金の resource が無い」ことは、Cost Explorer ではなく構成で確認する。Cost Explorer への反映は翌日以降になり、動作確認の完了判定に使えない。`terraform plan` と `terraform state list` の出力に、ALB、RDS、NAT Gateway、Elastic IP、Secrets Manager が含まれないことを確認する。

**テスト方針**

| 検証すること | 手段 |
| --- | --- |
| 構成に時間課金の resource が無い | `terraform plan` の出力に ALB / RDS / NAT Gateway / Elastic IP / Secrets Manager が現れないことを確認する |
| 起動 script で到達できるようになる | 起動 script を実行し、`https://review-backend-nanitabe.<hosted zone>/graphql` へ `POST` して応答を得る |
| PC 以外の端末から到達できる | スマホから同じ URL を叩く。これが今回の主目的であり、代替手段で確認したことにしない |
| IP 直アクセスが弾かれる | task の public IP へ直接 `POST` し、403 が返ることを確認する |
| 停止 script で到達できなくなる | 停止 script を実行し、同じ URL が応答しなくなることを確認する |
| 30 分で自動停止する | 起動後に停止操作をせず 30 分待ち、到達できなくなることと `desired_count` が 0 になっていることを確認する |
| migration が流れる | 起動時の log に migration の実行が現れることを CloudWatch Logs で確認する |

30 分の自動停止は待ち時間が発生するが、要件の中心であるため 1 回は実測する。schedule の実行時刻を短く設定して代用すると、実際に使う 30 分の設定を検証しないまま完成にすることになる。

## 論点12: AWS resource を選ぶときの金額判断を document 化する

**ステータス:** 保留

**種別:** TBDヒアリング

この論点は、backend の動作確認環境を作るという今回の discussion 目的の外にある。論点11で金額判断の材料が揃ったことを受けてユーザーが記録を指示したため、独立した後続テーマとして置く。論点11の child にはしない。この論点の結論がどうなっても、論点11の決定（alarm を入れる、log を無期限で保持する、停止中の課金を月 $1 以内に収める）と今回の実装範囲は変わらないためである。

### この論点で扱うこと

AWS resource を構成へ含めるかどうかを金額で判断するときの基準を、repository の document として残すかを決める。決めるのは、基準の内容、置き場所、適用範囲である。

今回の steering で materialize した判断材料:

- 停止中の課金が発生する resource には、時間課金（ALB、RDS、NAT Gateway、Elastic IP のように存在するだけで課金される）と、保存・件数課金（ECR の image、CloudWatch Logs、alarm）がある。両者を同じ基準で扱うと判断を誤る。
- 「常時課金の resource を含めない」という形の基準は、少額で損失を防ぐ resource を機械的に退ける。実際に論点11の提案0で、月 $0.10 の alarm をこの理由だけで退けた。
- 判断には損益分岐の計算が要る。alarm の年額 $1.2 に対し、止め忘れた Fargate task は 3 日で $0.86、1 か月で $8.6 になる。防ぐ対象の損失と、防ぐための固定費を並べて比べる。
- 同じ目的を達成する手段が複数あるとき、額が桁で違うことがある。止め忘れの検知では、Container Insights（月 $3 から $6）と標準 metric + alarm（月 $0.10）が同じ判定を実現する。

### 再開条件

今回の steering の実装とユーザー動作確認が完了し、review 環境が動く状態になった後に再開する。今この論点を進めないのは、金額判断の基準を一般化するより先に、今回の構成を実際に動かして実測値を得るほうが、基準の具体性が上がるためである。

再開時に決めること: 基準を document 化するかどうか、する場合の置き場所（`infrastructure/README.md` の節にするか独立した file にするか）、適用範囲（この repository の AWS resource 全般か、review 環境に限るか）。
