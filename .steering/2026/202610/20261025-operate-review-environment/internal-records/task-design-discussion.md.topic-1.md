# 内部検討記録: 論点1 — frontend の動作確認環境の目的と、向く backend

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点1

## 開始context

依頼は「動作確認環境運用できるようにしたい」、issue #280 は「フロントエンドの動作確認環境をamplifyで立てる」。前の roadmap で、frontend の動作確認環境は本番の Amplify app に branch を足さず、review root から `modules/amplify` を `stage = "review"` で呼んで別の app として作ると決めた。作ることを範囲外にした理由は「frontend の review がどの backend を向くかという判断を本番移行へ持ち込まないため」だった。

- 決める範囲: 動作確認環境で何を確かめるか（目的）と、frontend の動作確認環境が向く backend。
- 既決条件: 別の Amplify app として review root から作ること。
- 残る不足: 目的。backend の向き先は目的から決まる。

<a id="iteration-0"></a>

## イテレーション0: 目的と backend の向き先

<a id="iteration-0-record-1"></a>

### 調査: 向き先の候補と、それぞれで起きること

- backend の review 環境は `https://review-backend-nanitabe.<hosted zone>/graphql` で応答し、開発 DB を共有する。普段は停止しており、`start.sh` で起動して 30 分で自動停止する（`backend/docs/ai_guideline/development_standard/review_environment.md`）。同 document は「frontend とは繋がない。画面から操作する確認はできない」を「できないこと」に挙げている。
- 本番の backend は本番のデータを持つ。動作確認環境の frontend から本番の backend を呼ぶと、確認のための操作（献立の登録・削除など）が本番のデータを変える。
- backend の CORS は `origins "*"` で、frontend の origin を限定していない。どちらの backend にも画面から到達できる。

<a id="iteration-0-record-2"></a>

### 判断: 推奨

- 目的は、backend の review 環境と同じく「`main` へ入れる前の変更を、PC 以外の端末から確かめる」を、画面の操作まで広げること。
- 向き先は backend の review 環境とする。frontend だけの変更でも本番のデータを変えずに確かめられ、frontend と backend にまたがる変更は両方を `review` に載せて組み合わせて確かめられる。
- 代償: 画面で確かめるたびに backend の review 環境の起動が要る（停止中は API が応答しない）。開発 DB のデータで確かめることになる。
