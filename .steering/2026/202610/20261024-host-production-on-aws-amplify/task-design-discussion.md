# 議論記録

## 論点1: x_favorites の Amplify 構成を真似る目的と範囲

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0（論点1）: 何を解消するために、どの要素を取り込むか

#### 認識合わせ0（論点1）

nanitabe の frontend は、すでに AWS 上で本番稼働する構成を持っています（Lambda、API Gateway、CloudFront、S3、ECR、CodePipeline、CodeBuild）。そのため今回の作業は「AWS に本番を新しく作る」ではなく、「既存の frontend 本番構成を x_favorites の形へ置き換える」になります。

x_favorites から取り込める要素は次の三つです。

1. Amplify Hosting による frontend 配信（`aws_amplify_app` の `WEB_COMPUTE` と `amplify.yml`。push で Amplify が build・配信する）
2. 常設の review branch（同じ Amplify app に `review` branch を足し、本番と同じ設定で `main` へ入れる前に確認する）
3. Terraform の GitHub Actions 適用（OIDC で AWS role を assume し、PR で plan、merge で apply する）

次の二点を確認したいです。

- a. 置き換えで解消したいことは何ですか。たとえば、構成の resource 数と保守の手間、費用、deploy 経路の不安定さ、x_favorites と構成を揃えること自体、など。複数あれば優先順位もお願いします。
- b. 上の 1〜3 のうち、どれを今回真似たいですか。

#### 検討記録（論点1・イテレーション0）

この回答が design 全体の上位になります。WHY が変わると、置き換える範囲と旧構成の扱いが変わります。たとえば「resource と保守の手間を減らしたい」なら 1 を主にして旧構成の撤去までが範囲になります。「deploy 前に確認する場所がほしい」なら 2 が主になります。

3 は既存の構成前提と衝突します。`infrastructure/README.md` の「構成上の前提」は「GitHub 側に AWS の credentials も OIDC の信頼設定も置かない。deploy は AWS 側が GitHub を見る形にし、`.github/workflows/` は test と lint だけを行う」と定めています。3 を取り込むなら、この前提を変える判断も今回の範囲に入ります。

backend は対象にしにくいと見ています。backend の本番 deploy はこの repository の Terraform の管理外で、Amplify Hosting は Rails の server を動かす service ではないためです。backend も AWS へ移したい意図があれば、b で教えてください。

現在の読解では、x_favorites で Amplify が少ない構成で動いたのを見て、nanitabe の自前構成（resource が多く、過去に「CD 整備後にバックエンド通信ができない」(#145、#154)、「CodeBuild が失敗している」(#161) があった）を簡素にしたい、という動機が最も自然に読めます。ただし依頼文には書かれていない推論なので、確定には使いません。

[内部検討記録: 論点1・イテレーション0](internal-records/task-design-discussion.md.topic-1.md#iteration-0)

#### 認識合わせ0への回答（論点1）

**結果:** 動機と取り込む要素を受領。2 は範囲に含めるかを提案側で判断する

> aについて。興味も含めて自分でCloudfrontやAPIGateway使ってフロントエンド環境を作ったけど、結局amplifyの内製だった。作りもわかった今、メンテコストが低いamplifyに移行したい。今後動作確認環境を作るのに、複製するのがだるかったというのもある。bについては1,3。2は終わった後に別ブランチでやろうと思っていた。ついでにここでやったほうが楽なら混ぜてもいい

- a: 自前の CloudFront・API Gateway 構成は学習を兼ねて作ったもので、Amplify が内部で提供しているものと同じだった。構造を理解した今は保守の手間が少ない Amplify へ移したい。加えて、動作確認環境を作るたびに自前構成を複製するのが負担だった。
- b: 1 と 3 を取り込む。2 は完了後に別 branch で行う予定だが、混ぜたほうが楽なら混ぜてよい。backend への言及はなく、対象外の見立ては否定されていない。


### イテレーション1（論点1）: 目的と範囲を確定する

#### 提案1（論点1）

**目的（design.md の TL;DR の WHY）**

学習を兼ねて自前で組んだ frontend の配信基盤（Lambda、API Gateway、CloudFront、S3、ECR、CodePipeline、CodeBuild）は、Amplify Hosting が managed に提供しているものと同じだった。構造を理解した今、この自前構成を Amplify へ移し、保守対象を減らす。あわせて、今後の動作確認環境を自前構成の複製ではなく branch の追加で作れる土台にする。

**範囲**

| 対象 | 扱い |
| --- | --- |
| frontend の本番配信を Amplify Hosting へ移す（x_favorites の要素 1） | 含める |
| 移行後に旧構成を撤去する（上記の AWS resource と、`frontend/terraform/` 配下・`frontend/buildOnLambda/` の定義） | 含める |
| Terraform の適用を GitHub Actions へ移す（要素 3） | 含める。`infrastructure/README.md` の「GitHub 側に AWS の credentials も OIDC の信頼設定も置かない」前提を変える判断も含む |
| 常設の review branch（要素 2） | 含めない。ただし今回の Amplify 構成は、branch を list で持ち、custom domain を branch ごとの sub domain の集合で持つ形にする。後から 2 を足す作業が list への追加で済むようにする |
| backend | 含めない |

各対象の具体的な形（環境変数の渡し方、domain の切替順、撤去順、OIDC role の権限、既存の review 環境の Terraform を Actions から適用するか等）は、この論点では決めない。後続の論点で一つずつ扱う。

#### 検討記録（論点1・イテレーション1）

認識合わせ0の回答で、目的は「保守の手間を減らす」と「動作確認環境の複製をやめる」、取り込む要素は 1 と 3 に確定しました。この回で判断したのは、委ねられた 2 の扱いと、回答に明示されていなかった旧構成の撤去です。

**2 を含めない理由。** frontend の review branch を作ると、それがどの backend を指すかという、本番移行と無関係な設計判断が入ります。backend の review 環境はすでに git の `review` branch を監視し、必要時だけ起動する ECS で動いています（`backend/docs/ai_guideline/development_standard/review_environment.md`）。止まっている時間が長いため、frontend の review が常にそれを指す形は成立しにくく、別の設計が要ります。一方、x_favorites では review branch の追加が `branch_names` への一要素と sub domain の一組の追加だけで済んでいて、証明書もワイルドカード形式のため再発行が起きません。今回の構成を同じ形にしておけば、後から足しても今回作るものを作り直しません。代償は review 環境が使えるのが移行後になることですが、元々の予定と同じです。

**旧構成の撤去を含める理由。** 旧構成を残したままだと、保守対象は Amplify の分だけ増えて減らず、目的を満たしません。

[内部検討記録: 論点1・イテレーション1](internal-records/task-design-discussion.md.topic-1.md#iteration-1)

#### 提案1へのフィードバック（論点1）

**結果:** 合意

> ok

### 決定（論点1）

**目的:** 学習を兼ねて自前で組んだ frontend の配信基盤（Lambda、API Gateway、CloudFront、S3、ECR、CodePipeline、CodeBuild）は、Amplify Hosting が managed に提供しているものと同じだった。この自前構成を Amplify へ移して保守対象を減らし、今後の動作確認環境を自前構成の複製ではなく branch の追加で作れる土台にする。

**範囲:**

- 含める: frontend の本番配信を Amplify Hosting へ移すこと。移行後に旧構成（上記の AWS resource と、`frontend/terraform/` 配下・`frontend/buildOnLambda/` の定義）を撤去すること。Terraform の適用を GitHub Actions へ移すことと、それに伴い `infrastructure/README.md` の「GitHub 側に AWS の credentials も OIDC の信頼設定も置かない」前提を変えること。
- 含めない: 常設の review branch、backend。

**制約:** 今回の Amplify 構成は branch を list で持ち、custom domain を branch ごとの sub domain の集合で持つ。後から review branch を足す作業を list への追加で済ませるためである。review branch を含めないのは、frontend の review がどの backend を指すかという本番移行と無関係な設計判断を持ち込むためである。旧構成の撤去を含めるのは、残すと保守対象が減らず目的を満たさないためである。

## 論点2: Amplify 移行と Terraform の Actions 移行の順序

**ステータス:** 応答待ち

### イテレーション0（論点2）: どちらを先に行うか

#### 提案0（論点2）

Amplify 移行を先に、現行の手元 apply（`infrastructure/terraform/envs/prod` の script）で行い、旧構成の撤去まで終える。その後に Terraform の適用を GitHub Actions へ移す。

```text
Amplify 移行（手元 apply）            Actions 移行
  Amplify app を作る                    OIDC と plan / apply の workflow を作る
  custom domain を切り替える      →     値を host の .env から GitHub secrets へ移す
  旧構成を撤去する                      以後の apply は PR と merge で行う
```

#### 検討記録（論点2・イテレーション0）

先に行う側が、後に行う側の実行経路と、GitHub へ移す値と権限の範囲を決めます。

Actions を先に行うと、現行の prod root をそのまま Actions から適用することになります。prod root は旧構成のために長期の IAM access key（`aws_access_key`、`aws_secret_access_key`）を受け取り、CodeBuild の環境変数へ平文で渡しています（`frontend/terraform/modules/cicd/codebuild/main.tf` に `# TODO: secret化する` とある）。この key を GitHub secrets へ置き、apply role に Lambda、API Gateway、CloudFront、ECR、CodePipeline、CodeBuild、ACM 等への権限を付ける必要が出ます。どれも Amplify 移行が終われば不要になります。

Amplify 移行を先に行えば、Actions へ移す時点の variable と apply role の権限は、Amplify 構成と state 用 resource の分だけになります。x_favorites も同じ順序（Amplify を手元 apply で成立させてから Actions へ移す）でした。本番移行の作業中に、適用経路の変更という別の不確実性を重ねずに済みます。

代償は、Amplify 移行の間だけ Amplify が GitHub へ接続するための値を host 上の `.env` に置くことです。Actions 移行時に GitHub secrets へ移します。

[内部検討記録: 論点2・イテレーション0](internal-records/task-design-discussion.md.topic-2.md#iteration-0)

#### 提案0へのフィードバック（論点2）
