# タスクリスト: カレンダーヘッダ固定化

## フェーズ1: sticky ラッパー div の除去

### DoD（完了条件）
- カレンダー画面をスクロールしてもヘッダが画面上部に固定表示される（週・月ビュー両方）
- 既存テストが全てグリーン
- ESLint エラーゼロ
- Playwright でスクロール後もヘッダが見えることを目視確認済み（visual-inspector サブエージェント使用）

### タスク

- [x] `Calendar/index.tsx` の header ラッパー `<div>` を除去
    - `children(...)` を外側 `<div>` の直接の子にする（ラッパー div を1段削除するだけ）

- [x] 動作確認（`visual-inspector` サブエージェント（`Agent(subagent_type="visual-inspector")`）を使うこと。`npx playwright` 等の直接呼び出し禁止）
    - [x] スクロール前のスクリーンショット
    - [x] スクロール後もヘッダが固定されていることを確認
    - [x] 週間ビュー・月間ビュー両方で確認

- [x] テスト実行
    - [x] `docker compose exec frontend yarn test`
    - [x] 全テストグリーン確認

- [x] リント実行
    - [x] `docker compose exec frontend yarn lint`
    - [x] エラーゼロ確認

---

## 実装後の振り返り

### 実装完了日
2026-03-15

### 計画と実績の差分

**計画と異なった点**:
-

**新たに必要になったタスク**:
-
