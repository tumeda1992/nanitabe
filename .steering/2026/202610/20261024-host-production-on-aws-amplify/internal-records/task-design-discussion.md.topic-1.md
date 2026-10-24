# 内部検討記録: 論点1 — x_favorites の Amplify 構成を真似る目的と範囲

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点1

## 開始context

依頼は「x_favorites で Amplify で本番環境を AWS に構築できるようになったから、真似したい」である。

- 「真似る」対象: x_favorites が 2026年9月に成立させた構成。Amplify Hosting による配信だけでなく、常設の review branch と、Terraform の GitHub Actions 経由の適用も同じ時期に入っている。
- 決める範囲: nanitabe で何を解消するために、x_favorites のどの要素を取り込むか。design.md の TL;DR、完成後の姿、要件のすべてがこの答えに依存する。
- 開始時の既決条件: なし。design.md は TBD 込みの初稿である。
- 残る不足: 取り込む動機（現行構成のどこが困っているのか）は依頼文から読めない。

<a id="iteration-0"></a>

## イテレーション0: 何を解消するために、どの要素を取り込むか

依頼文だけを入口にする。先に両 repository の現行構成を調べ、依頼文の「本番環境を AWS に構築」が nanitabe の何を指しうるかを特定してから、ユーザーにしか答えられない前提を絞る。

<a id="iteration-0-record-1"></a>

### 調査: nanitabe の現行本番構成と、x_favorites から取り込める要素

#### 問いと探索範囲

- 問い: nanitabe の本番はすでに AWS 上にあるのか。x_favorites のどの要素が nanitabe に対して差分になるのか。
- source: nanitabe の `infrastructure/README.md`、`frontend/README.md`、`frontend/terraform/`、`frontend/buildOnLambda/`、`.github/workflows/`。x_favorites の `terraform/README.md`、`terraform/modules/amplify/`、`amplify.yml`、`.steering/2026/202609/` 配下の各 `design.md` の TL;DR。
- 方法: 構成定義と README を読み、x_favorites の要素ごとに nanitabe 側の対応物を照合する。

#### 見つかった事実

nanitabe の frontend はすでに AWS 上で本番稼働する構成を持つ。

- Next.js を container image にして Lambda で動かし、API Gateway を origin とする CloudFront から配信する。static asset は image build 中に S3 へ同期する（`frontend/buildOnLambda/Dockerfile`）。
- deploy は CodePipeline と CodeBuild（ARM）が担う（`frontend/terraform/modules/cicd/`）。
- backend を指す `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN` は image build 時に焼き込む。
- 過去の PR に「フロントエンドの CD 整備後、バックエンド通信ができない」（#145、#154）、「CodeBuild が失敗している」（#161）がある。現行の deploy 経路で障害が起きた履歴がある。

nanitabe の backend の本番 deploy は `.github/workflows/backend-deploy.yml` が外部 webhook を呼ぶ形で、この repository の Terraform の管理外である。Amplify Hosting は Rails の server を動かす service ではないため、backend をそのまま載せる先にはならない。

x_favorites から取り込める要素は三つに分かれる。

| 要素 | x_favorites での形 | nanitabe の現状との差 |
| --- | --- | --- |
| Amplify Hosting による frontend 配信 | `aws_amplify_app`（`WEB_COMPUTE`）と `amplify.yml`。GitHub への push で Amplify が build・配信する | nanitabe は Lambda、API Gateway、CloudFront、S3、ECR、CodePipeline、CodeBuild を自前で組んでいる。置き換えると resource 数と build 経路が減る |
| 常設の review branch | 同じ Amplify app に `review` branch を足し、本番と同じ build 設定・環境変数で確認する | nanitabe には backend 用の review 環境（ECS、必要時だけ起動）がある。frontend の review 環境は無い |
| Terraform の GitHub Actions 適用 | OIDC で AWS role を assume し、PR で plan、merge で apply | nanitabe は host 上の `.env` を読む script で手元から適用する。`infrastructure/README.md` は「GitHub 側に AWS の credentials も OIDC の信頼設定も置かない」を構成上の前提としている。取り込むならこの前提を変える |

#### 言える範囲

「本番環境を AWS に構築」は、nanitabe では「AWS 上に初めて本番を作る」ではなく、「既存の frontend 本番構成を Amplify へ置き換える」以上の意味を持ちうる。三要素のどれを取り込むかで設計対象が大きく変わり、三つ目は既存の構成前提と衝突する。どれを取り込むかを決めるには、置き換えで何を解消したいかが要る。これは repository からは読めない。

<a id="iteration-0-record-2"></a>

### 認識合わせ: 取り込む動機と、取り込みたい要素

#### 共有できる事実と、現在の読解

上の調査のとおり、frontend はすでに AWS 上にあり、Amplify へ寄せることは「置き換え」になる。読解としては、x_favorites で Amplify が少ない構成で動いたのを見て、nanitabe の自前構成（resource が多く、過去に deploy 経路の障害があった）を簡素にしたい、という動機が最も自然に読める。ただし、これは依頼文に書かれていない推論である。

#### 本人にしか確定できない前提

- 置き換えで何を解消したいか。運用・保守の手間、費用、deploy の不安定さ、構成を x_favorites と揃えること自体、など。
- x_favorites の三要素のうち、どれを真似たいと考えているか。とくに Terraform の GitHub Actions 適用は、nanitabe の「GitHub 側に AWS credentials も OIDC も置かない」前提を変えることになる。

回答によって、TL;DR の WHY、設計対象の範囲（frontend 配信だけか、review branch、Terraform の適用経路まで含むか）、旧構成を撤去するかが決まる。

<a id="iteration-1"></a>

## イテレーション1: 回答を受けて、目的と範囲を一つの案にする

認識合わせ0の回答で、動機（保守の手間を減らす。動作確認環境の複製が負担だった）と、取り込む要素（1 と 3）が確定した。2 だけが「混ぜたほうが楽なら混ぜてよい」と判断を委ねられている。この回では、2 を今回の範囲へ含めるかと、旧構成の撤去を範囲へ含めるかを判断して案にする。

<a id="iteration-1-record-1"></a>

### 判断: review branch を今回の範囲へ含めるか

#### 判断対象と評価軸

- 判断対象: x_favorites の要素 2（常設の review branch）を、この steering で一緒に作るか。
- 評価軸: 本番移行の検証範囲を広げないか。今回作るものの形が、後から 2 を足すときの手戻りを生まないか。

#### 材料

- `backend/docs/ai_guideline/development_standard/review_environment.md` によると、backend の review 環境はすでに git の `review` branch を監視しており、必要時だけ起動する ECS で動く。frontend の review branch を作るなら、どの backend を指すか（backend の review 環境か、本番の backend か）と、同じ `review` branch を共有するかが新しい設計判断として発生する。backend の review 環境は止まっている時間が長いため、frontend の review が常時その backend を指す形は成立しにくい。
- x_favorites の review branch 追加は、`branch_names` への一要素の追加と、`custom_domain_sub_domains` への一組の追加で済んでいる（x_favorites の `terraform/modules/amplify/README.md`）。Amplify の domain association が発行する証明書はワイルドカード形式で、branch を足しても再発行が起きない。

#### 推奨と代償

2 は今回の範囲へ含めない。backend との組み合わせという、本番移行と無関係な設計判断を持ち込むためである。今回の Amplify 構成は x_favorites と同じく branch を list で持ち、domain association を branch ごとの sub domain の集合として持つ形にする。こうすれば、2 を後から足す作業は git branch の作成と list への追加になり、今回の構成を作り直さない。

代償は、review 環境を使えるようになるのが本番移行の後になることである。ユーザーは元々別 branch で行う予定だったため、この代償は予定と一致する。

<a id="iteration-1-record-2"></a>

### 判断: 旧構成の撤去を今回の範囲へ含めるか

- 判断対象: Amplify へ移した後、Lambda、API Gateway、CloudFront、static asset 用 S3、ECR、CodePipeline、CodeBuild と、それを定義する `frontend/terraform/` 配下・`frontend/buildOnLambda/` を撤去するか。
- 材料: 動機は保守の手間を減らすことである。旧構成を残すと、保守対象は Amplify の分だけ増え、減らない。
- 推奨: 撤去を範囲へ含める。撤去の順序（domain の切替を先に確認してから旧 resource を消すか等）は、この論点ではなく後続の論点で決める。

<a id="iteration-3"></a>

## イテレーション3: Actions 移行を別 steering へ分けるか

論点2〜6で Amplify 移行の設計が埋まった。次に Actions 移行の設計へ入る前に、Actions 移行が持つ設計判断の量と、本番 build が止まっているという緊急性（イテレーション2）を照らし、同じ steering で扱い続けるかを見直す。イテレーション2の時点では範囲を変えないとしたが、その後の調査で Actions 移行側の論点の量が分かったため再開する。

<a id="iteration-3-record-1"></a>

### 調査: Actions 移行で決める必要がある事項

- 適用対象の root: nanitabe には `envs/prod` と `envs/review` の二つの root がある。x_favorites は一つだった。`envs/review` の `apply_terraform.sh` は agent が permission を持って実行する前提で、destroy を含む plan を拒否する判定を script 自身が持つ（`infrastructure/README.md`）。Actions へ移すなら、この判定と agent の実行権限の扱いを決め直す。
- apply role の権限: Amplify 移行後の `envs/prod` は Amplify と state 用 resource だけで済む（論点2）。`envs/review` は ACM、API Gateway v2、CloudWatch、ECR、ECS、IAM role、Route53、security group、SNS、SSM、CodePipeline、CodeBuild、Scheduler を持つ（`backend/terraform/modules/` の resource 種別）。IAM role を作れる権限を Actions の role へ渡すかは独立した判断になる。
- secret の移動: `envs/review` は DB の接続情報と `RAILS_MASTER_KEY` を variable で受ける。Actions へ移すと、これらを GitHub secrets へ置くことになる。
- その他: state の lock を DynamoDB のまま使うか、`infrastructure/README.md` の「GitHub 側に AWS の credentials も OIDC の信頼設定も置かない」前提をどう書き換えるか、public repository で使える branch protection を使うか。

<a id="iteration-3-record-2"></a>

### 判断: 分けるか

- 評価軸: 本番 build の停止を早く解消する。Actions 移行を Amplify 移行の実測結果の上で設計する。
- 推奨: Actions 移行をこの steering から外し、Amplify 移行の完了後に別 steering で設計・実行する。論点2の決定により Actions 移行は Amplify 移行の後にしか始まらないため、同じ steering に入れても並行して進む部分は無い。分ければ、この steering は Amplify 移行だけで完了でき、本番 build の停止を設計の残りを待たずに解消できる。
- 代償: issue #258 を閉じる時期が、二つ目の steering の完了まで延びるか、Actions 移行に別 issue を立てるかの選択が生じる。

<a id="iteration-4"></a>

## イテレーション4: 分ける理由の再検討と、同じテーマ内で段階化する方法

提案3へのフィードバックで、「決める事項が多い」は分ける根拠にならないこと、別 steering は同じテーマの外へ追い出しているだけに見えること、roadmap 等と比較していないことが指摘された。

<a id="iteration-4-record-1"></a>

### 診断: 提案3の根拠がどこで外れたか

- 期待: 分ける判断は、分けないと何が困るかで決まる。
- 実際: 提案3は Actions 移行側の事項の多さを並べた。事項の多さは、x_favorites をほぼ踏襲できるなら負担にならない。
- 原因: 「範囲から外す」と「同じテーマ内で後段へ回す」を区別せず、最初に思いついた別 steering だけを案にした。分けないと困ることの本体は、Actions 移行の設計完了まで Amplify 移行の実行（本番 build 停止の解消）が待たされることである。
- この原因は成果物固有ではなく、範囲を外す提案を作るときの process の問いの不足でもある。skill 改善の候補として、Step 4 の再発防止 review で扱う。

<a id="iteration-4-record-2"></a>

### 判断: 別 steering と roadmap の比較

| 観点 | 別 steering | roadmap の二 phase |
| --- | --- | --- |
| Amplify 移行を先に実行できるか | できる | できる。依存の先頭 phase として実行する |
| Actions 移行がこのテーマの完了条件に残るか | 残らない | 残る |
| Actions 移行の設計を Amplify 移行の実物を見て行えるか | できる | できる。子 task-design へ dependency results として渡す |
| issue | 分ける必要が出る | #258 一つで足りる |

推奨は roadmap の二 phase。roadmap-design の条件（二つ以上の子 scope、各子が親より strictly narrower、依存が DAG、各 phase 完了時点で app が正常に使える）も満たす。「Amplify 移行」完了時点で本番は Amplify で動き、Terraform は手元 apply のまま正常に運用できる。
