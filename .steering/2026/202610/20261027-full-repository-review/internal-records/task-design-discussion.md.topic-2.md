# 内部検討記録: 論点2 — backend CIを本体実行・成功まで修復する

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点2

## 開始context

利用者の新しい指摘は「PR見たらbackendのテストもrubocopも落ちてるけど」。
先行採用範囲の検証sourceは`3d832f5`、追加設計開始時HEADは`b7d2d4a`で、既存tasklistは全完了である。
過去sourceの検証結果を保持し、今回変更したsourceとPR上のCI本体成功を別に記録する。
これは親Solが調査・確定した方針を受けた事後記録であり、本担当がCI logや公式文書を独立再取得した記録ではない。

<a id="iteration-1"></a>

## イテレーション1: runnerと既存lintの2原因を限定修正する

<a id="iteration-1-record-1"></a>

### 判断: 既存Rubyと認証仕様を保持してCIを通す

親Solの調査ではCI Backend Test `42195382480`とCI Backend Rubocop `42195382436`は、
`Unavailable version 3.3.8 for ruby on ubuntu-26.04`でSetup Rubyが失敗し、本体を実行していない。
親SolがGitHub connectorで取得した[ruby/setup-ruby公式README](https://github.com/ruby/setup-ruby#readme)は、
新runnerが各系列最新patchだけを提供し、旧patch厳密指定には`ubuntu-24.04`固定を推奨している。
本担当は両workflowの`ubuntu-latest`と`ruby-version: '3.3.8'`を現物確認した。
Ruby/Gemfile/lockを変えず、両workflowのrunnerだけを固定すれば実行基盤の不整合を除ける。

親Solは次の既知失敗として`backend/app/controllers/admin/base_controller.rb`の
Style/FetchEnvVar 2件を特定した。本担当も`ENV["ADMIN_USERNAME"]`と`ENV["ADMIN_PASSWORD"]`、
認証test helperとauthorization specのENV[] stubを現物確認した。
既定nilを明示する`ENV.fetch(key, nil)`なら未設定/空文字の拒否と正誤credentialの既存意味を保つ。
対応するstubだけを`fetch(key, nil)`へ適応し、認証機能の変更、lint抑制、低impact記法を写すだけの新testは追加しない。

この2原因は環境runnerと認証のlint記法で別々にrevertできるため、別commitにする。
既存の認証/管理CRUD request/system、backend全RSpec・全RuboCop、YAML parseを実行し、
push後にPRのRSpec/RuboCop本体が実際に成功したことを確認して閉じる。
本担当は設計lifecycleだけを更新する。実装はTerra、test-runnerは親Solがphysical ownerとなる。
新source検証、CI URL/SHA、旧記録への追記、PR説明の訂正をexecutorへ渡す。
