# 追加再現の証拠

これらは不具合の現行挙動を期待するcharacterization testである。**成功は「不具合が再現した」を意味し、修正済みではない。** アプリケーションコードと既存テストは変更していない。

## 実測

| probe | 観測結果 |
| --- | --- |
| backend 1 | AのGraphQL食事登録がBの料理IDを受け入れ、A向けFinderにBの料理名が出る |
| backend 2 | AのパターンがBの枠を受け入れ、GraphQL一覧にBの枠名が出る |
| backend 3 | 割当済み食事を翌日へ移動すると、旧日は空応答になるが旧日付の割当済み枠がDBに残る |
| backend 4 | 2枠に同じ食事を割り当てた結果、同じmeal_idの枠が2件存在する |
| backend 5 | 未認証で管理画面GETがHTTP 200になる |
| backend 6 | 辞書source「[」でRegexpErrorになる |
| frontend 1 | 枠の選択を「--」へ戻すとsubmitへNaNが渡る |
| frontend 2 | Next pathnameを変更して再描画しても論理historyの旧pathが残る |

実行ログ: [backend](backend-probes.log)、[frontend](frontend-probes.log)。backend 6 examples成功、frontend 2 tests成功。

## 再現方法

既存の隔離テスト用コンテナとダミー認証設定を使用した。backend probeはアプリrootを`/app`としてrails_helperを読み込む。`backend-probes.rb`をコンテナの`/tmp/`へコピーし、アプリrootで`RAILS_ENV=test bundle exec rspec /tmp/backend-probes.rb`を実行する。

frontend probeはHEADと同じソースを持つコンテナ内の検証用コピーに配置した。`frontend-probes.spec.tsx`をその`frontend/src/review-probe.spec.tsx`へコピーし、frontend rootで`yarn test --runInBand --silent src/review-probe.spec.tsx`を実行する。相対importはsrc配置を前提にしている。

probeの初回には、既存認証helperのuserid引数不一致とJest setupがlocation.pathnameを持たないことにより2ケースが失敗した。前者はFR-031として独立記録し、probeでは発行済みheadersを再利用した。後者はprobeにpathname/searchを与えて修正した。最終ログは修正後の再実行結果である。

既存回帰はfrontend 39 suites / 215 tests、backend `spec/domain/business/food spec/graphql` 568 examplesが成功。backend全体RSpecの追加実行は完了しておらず、全テスト成功とは記載しない。
