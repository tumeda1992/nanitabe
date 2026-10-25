# verify-infra

Terraform の定義が、手元からの実行で意図どおりに動くかを確かめるための、spike 的な環境。

`prod` と `review` の state を扱う適用とは切り離し、手元で apply して確かめる。`prod` と `review` の適用経路は `infrastructure/README.md` が説明する。

## いつ使うか

不確実性を、本番や review へ入れる前に部品の単位で潰したいときに使う。

- 一つ一つの resource や設定に不確実性があり、apply してみないと挙動が分からないとき
- ちょっと試したいレベルの新しい resource を、軽く使ってみるとき
- 既存の本番を破壊的に変える必要があり、試しなしでは行えないが、部品に切り出せば試せるとき

かっちりした初回作成は verify-infra を経ない。本番ライクな構成を、prod や review の定義へ直接積み上げていく。

- やってしまいがちな失敗: 新しい module を作るたびに、紋切り型で verify-infra 用の定義も用意する
- それをやると何が起きるか: 使われない spike の定義と、立てたまま忘れられた resource が残る
- 正しい判断のための問い: 「apply してみないと分からないことが、今あるか。それは本番の定義へ直接積み上げては確かめられないか」

## どう使うか

- 必要になったときに、確かめたい module を呼ぶ root（`main.tf`）を作る。置き場所はこの directory の下でも、対象 module の `test/` でもよい。
- state は local state にする。`prod` や `review` の S3 の state を使わない。`*.tfstate` は `.gitignore` の対象で commit されない。
- `stage` などの名前は `verify-infra` とし、`prod` や `review` の resource と名前を重ねない。
- 必要な値は、その spike が使うものだけを個別に渡す。`prod` や `review` の値の一式を前提にしない。
- 確かめ終わったら destroy する。立てたまま残さない。

MUST: 確かめた後に destroy する。local state は手元にしか無いため、立てたまま root や module を削除すると、resource を Terraform から消す手段を失う。

旧構成では、各 module の `test/` から stage `verify-infra` で立てていた環境が、module の撤去後も手元の state だけで残り、撤去の洗い出しから漏れた（`.steering/2026/202610/20261024-migrate-frontend-hosting-to-amplify/implementation_review.md` 論点8）。
