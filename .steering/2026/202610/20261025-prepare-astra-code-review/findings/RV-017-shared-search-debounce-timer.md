# RV-017: 料理検索のdebounce timerが全インスタンスで共有される

- 観点: 契約・正しさ・運用
- 優先度: 中
- 採否: 採用（後続の全件反映指示）
- 対応状況: 完了（FR-016で追跡）
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: frontend/src/components/dish/DishSearchPanel/index.tsx: searchTimer、handleSearchChange
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

searchTimerがモジュール直下にあるため、複数の検索パネルで一方の入力が他方の予約をclearTimeoutする。unmount時にも予約を解除しないため、閉じたパネルのcallbackが後から走る。コンポーネントローカルの検索状態に対してタイマーの寿命だけがグローバルになっている。

## 改善案

useRefでインスタンスごとにタイマーを持ち、unmount時にclearTimeoutする。400msのdebounce値は維持する。

## 振る舞いを維持する条件

複数表示や閉じた後のcallbackが変わるため対象外。初期検索語がinput表示へ反映されない問題まで同時に修正しない。

## 検証方法

fake timersで2パネルへ連続入力し、それぞれ独立に反映されること、unmount後にonSearchStringChangeが呼ばれないことを検証する。

## 採否・対応記録

- ユーザーの判断: 後続の全件反映指示により採用（FR-016）
- 初回確認: コードと記載した関連specの静的確認。後続の検証結果は以下のFR記録を参照。
- 適用コミット: `5319fbd`

## 後続の反映（2026-11-02）

本fileの「今回の適用対象」は初回の挙動維持枠を指す。後続の全件反映指示による現行状態・検証は[FR-016](../../20261027-full-repository-review/findings/FR-016-search-timer.md)へ集約する。適用commitは`5319fbd`。
