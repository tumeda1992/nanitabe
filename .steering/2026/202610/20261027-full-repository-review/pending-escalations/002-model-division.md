# 保留メモ: モデルの役割分担

## 保留時の内容

利用者の依頼は、方針検討、進行のハンドリング、エージェントの結果監督をsolが担い、それ以外をterraに委ねる役割分担をpluginへescalateすること。assistantは実装・調査・テスト等をterraへ委ねる例と捉え、利用者のモデル選択と実行環境のモデル制約を優先する前提で、`runtime-model-profiles` 等への提案候補とする。具体的な適用先や規則は未合意である。

出典は2026-11-06の実際の会話。利用者は「solじゃないといけないのは方針検討とハンドリングとエージェントがやってることの結果監督で、あとはterraに投げていいよ。これもescalate案件」と述べた。その後、assistantがplugin先行で元作業を止めると応答したことに対し、利用者は「escalateは保留するモードあるだろ。切り戻し作業を止めた状態を保つなよ、続けろよ」と指示した。

この元作業では改善の引渡しを今は保留し、元作業を優先する。再開条件は利用者の保留解除指示であり、元作業の再開や完了は自動引渡しの条件ではない。

## 追跡

### 現在の状態（2026-11-14確認）

状態: 実装・merge・利用先導入確認済み。[plugin PR #14](https://github.com/tumeda1992/ai_agent_dev_skill_plugin/pull/14) がmergeされ、version `8.3.1` の導入完了記録とsource commit `b6bae67dabb8d518e8b17131121f80b0a1f1d0cb` を照合した。
役割分担の適用先は `exhaustive-review` に限定され、hostの制限はない。
Solが方針検討、ハンドリング、agent結果の監督を担い、読取、事実調査、確定済み方針の実装、テスト等はTerraへ委譲できる。
全作業のchild化は必須ではなく、利用者の明示model指定と実環境の選択可能性を優先する。ほかのskill全般への役割分担指定としては扱わない。

### 引渡し時の記録（2026-11-07）

当時の状態: 引渡し済み。2026-11-07の利用者発話「マージした。じゃあescalate片付けようか」で保留が解除された。plugin側の作業directory basenameは `20261107-resolve-deferred-review-workflow-improvements`。受領記録は `/tmp/tumeda-dev-20261107-resolve-deferred-review-workflow-improvements/.steering/2026/202611/20261107-resolve-deferred-review-workflow-improvements/escalation-receipt.md`。親担当が受領記録の全文を実読し三件と状態を確認した。2026-11-07のplugin側担当 `/root/plugin_design` の受領応答: 「受領済み・設計中、詳細未合意・source未変更を明記」。受領時点では詳細は設計中であり、実装は未完了だった。
