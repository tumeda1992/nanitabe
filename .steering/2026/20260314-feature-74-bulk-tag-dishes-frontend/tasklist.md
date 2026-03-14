# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

---

## フェーズ1: GraphQL codegen

### DoD
- `bulkAddTagToDishes` の型・hookが生成されている

### タスク

- [ ] codegenを実行して `bulkAddTagToDishes` の型・hookを生成する
    - [ ] `docker compose exec frontend yarn codegen`
    - [ ] `frontend/src/lib/graphql/generated/graphql.ts` に `BulkAddTagToDishMutation`、`useBulkAddTagToDishMutation` が生成されていることを確認

---

## フェーズ2: mutation hook の実装

### DoD
- `useBulkAddTagToDishes` hook が呼べる

### タスク

- [ ] `frontend/src/features/dish/tag/bulkAddTagMutation.ts` を新規作成
    - [ ] `BULK_ADD_TAG_TO_DISHES` gql クエリを定義
    - [ ] `useBulkAddTagToDishes` hookを実装（`removeDishMutation.ts` と同パターン）

---

## フェーズ3: BulkTagDrawer コンポーネントの実装

### DoD
- タグ名を入力して追加ボタンを押すと mutation が呼ばれ、ドロワーが閉じる
- テストがグリーン

### タスク

- [ ] specを書く（テストファースト）
    - [ ] `frontend/src/components/dish/BulkTagDrawer/index.spec.tsx` を新規作成
        - [ ] タグ名が空のとき追加ボタンが無効
        - [ ] タグ名入力後に追加ボタンを押すと `bulkAddTagToDishes` が呼ばれる
        - [ ] mutation 成功でドロワーが閉じる（`onOpenChange(false)` が呼ばれる）
- [ ] `frontend/src/components/dish/BulkTagDrawer/index.tsx` を新規作成
    - [ ] props: `open`, `onOpenChange`, `dishIds: Set<number>`
    - [ ] tagName state + テキスト入力 + 「追加」ボタン
    - [ ] open変更時に入力をリセット
    - [ ] 追加ボタン押下で `useBulkAddTagToDishes` を呼び、成功で `onOpenChange(false)`
- [ ] テスト実行・グリーン確認
    - [ ] `docker compose exec frontend yarn test src/components/dish/BulkTagDrawer`

---

## フェーズ4: dishes ページへの組み込み

### DoD
- フローティングバーに「タグを付ける」ボタンが表示される
- ボタン押下でドロワーが開き、タグ付けができる

### タスク

- [ ] `frontend/src/app/dishes/page.client.tsx` を変更
    - [ ] `bulkTagOpen` state を追加
    - [ ] フローティングバーのアクションボタン群に「タグを付ける」ボタンを追加（`Tag` アイコン使用）
    - [ ] `<BulkTagDrawer>` を追加（`open={bulkTagOpen}`, `dishIds={selectedIds}`）
    - [ ] mutation 成功時に選択を解除する（`onCompleted` で `setSelectedIds(new Set())`）

---

## フェーズ5: 品質チェックと修正

### DoD
- 全テストがグリーン
- ESLint エラーがない（プロジェクト全体）
- スクリーンショットで見た目を目視確認済み

### タスク

- [ ] 全テスト実行・グリーン確認
    - [ ] `docker compose exec frontend yarn test`

- [ ] ESLint 実行（プロジェクト全体）
    - [ ] `docker compose exec frontend yarn lint`
    - [ ] エラーがあれば修正して再実行（`yarn lint --fix`）
    - [ ] エラーゼロ確認

- [ ] スクリーンショットで見た目を目視確認
    - [ ] Playwright で `/dishes` を開き、料理を複数選択した状態のスクリーンショットを撮る
    - [ ] 「タグを付ける」ボタンが表示されているか確認
    - [ ] ドロワーを開いた状態のスクリーンショットを撮る
    - [ ] レイアウト・ボタン配置が意図通りか確認
    - [ ] 問題があれば修正して再確認

---

## フェーズ6: ドキュメント更新

- [ ] doc-enricher スキルを利用したREADME.md を更新（必要な場合のみ）
- [ ] 実装後の振り返り（このファイルの下部に記録）

---

## 実装後の振り返り

### 実装完了日
{YYYY-MM-DD}

### 計画と実績の差分

**計画と異なった点**:
-

**新たに必要になったタスク**:
-

**技術的理由でスキップしたタスク**（該当する場合のみ）:
-
