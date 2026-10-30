# RV-017: 料理検索のdebounce timerが全インスタンスで共有される

- 観点: 契約・正しさ・運用
- 優先度: 中
- 採否: 未判断
- 対応状況: 未着手
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

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
