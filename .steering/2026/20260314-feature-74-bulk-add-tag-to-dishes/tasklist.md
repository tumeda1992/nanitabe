# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

---

## フェーズ1: Dish::Root#add_tag の実装

### DoD
- `Dish::Root#add_tag` が追加され、重複チェックを含むビジネスロジックを持つ
- ユニットテストがグリーン

### タスク

- [ ] `add_tag` のspec を書く（テストファースト）
    - [ ] `spec/domain/business/food/dish/root_spec.rb` に `add_tag` のテストを追加
        - [ ] タグが追加される（正常系）
        - [ ] 正規化後内容が同じタグは重複追加されない
        - [ ] 型が不正なタグはエラー
- [ ] `Dish::Root#add_tag` を実装する
    - [ ] `app/domain/business/food/dish/root.rb` に `add_tag` を追加
    - [ ] 重複チェックは `content.normalized` で比較
- [ ] テスト実行・グリーン確認
    - [ ] `docker compose exec backend bundle exec rspec spec/domain/business/food/dish/root_spec.rb`

---

## フェーズ2: AddTagToDishCommand の実装

### DoD
- `AddTagToDishCommand` が単一Dishに対してタグを追加できる
- テストがグリーン

### タスク

- [ ] specを書く（テストファースト）
    - [ ] `spec/domain/business/food/dish/tag/usecase/add_tag_to_dish_command_spec.rb` を新規作成
        - [ ] 正常系: 指定DishにTagが追加される
        - [ ] 存在しないdish_idはエラー
- [ ] `AddTagToDishCommand` を実装する
    - [ ] `app/domain/business/food/dish/tag/usecase/add_tag_to_dish_command.rb` を新規作成
    - [ ] `dish_root.add_tag` を呼び、`Dish.persist_from_food_dish_root` で保存
- [ ] テスト実行・グリーン確認
    - [ ] `docker compose exec backend bundle exec rspec spec/domain/business/food/dish/tag/usecase/add_tag_to_dish_command_spec.rb`

---

## フェーズ3: BulkAddTagToDishesCommand の実装

### DoD
- `BulkAddTagToDishesCommand` が複数Dishに対して一括タグ追加できる
- テストがグリーン

### タスク

- [ ] specを書く（テストファースト）
    - [ ] `spec/domain/business/food/dish/tag/usecase/bulk_add_tag_to_dishes_command_spec.rb` を新規作成
        - [ ] 正常系: 複数DishにTagが追加される
        - [ ] 存在しないdish_idが含まれる場合はトランザクションがロールバックされる
        - [ ] dish_idsが空の場合はエラー
        - [ ] tag_contentが空の場合はエラー
- [ ] `BulkAddTagToDishesCommand` を実装する
    - [ ] `app/domain/business/food/dish/tag/usecase/bulk_add_tag_to_dishes_command.rb` を新規作成
    - [ ] トランザクション内で `AddTagToDishCommand` を各dish_idに対して呼ぶ
- [ ] テスト実行・グリーン確認
    - [ ] `docker compose exec backend bundle exec rspec spec/domain/business/food/dish/tag/usecase/bulk_add_tag_to_dishes_command_spec.rb`

---

## フェーズ4: GraphQL mutation の実装

### DoD
- `bulkAddTagToDishes` mutation が動作する
- GraphQL specがグリーン

### タスク

- [ ] specを書く（テストファースト）
    - [ ] `spec/graphql/mutation/dish/tag/bulk_add_tag_to_dishes_spec.rb` を新規作成
        - [ ] アーキテクチャ疎通確認（正常系1ケース）
- [ ] GraphQL mutation を実装する
    - [ ] `app/graphql/mutations/dish/tag/bulk_add_tag_to_dishes.rb` を新規作成
        - [ ] arguments: `dish_ids: [Int!]!`, `tag: String!`
        - [ ] returns: `dish_ids: [Int]`
        - [ ] `BulkAddTagToDishesCommand` を呼ぶ
    - [ ] `app/graphql/types/mutation_type.rb` に `bulk_add_tag_to_dishes` を登録
- [ ] テスト実行・グリーン確認
    - [ ] `docker compose exec backend bundle exec rspec spec/graphql/mutation/dish/tag/`

---

## フェーズ5: 品質チェックと修正

### DoD
- 全テストがグリーン
- Rubocop エラーがない（プロジェクト全体）

### タスク

- [ ] 全テスト実行・グリーン確認
    - [ ] `docker compose exec backend bundle exec rspec`

- [ ] Rubocop 実行（プロジェクト全体）
    - [ ] `docker compose exec backend bundle exec rubocop`
    - [ ] エラーがあれば修正して再実行
    - [ ] エラーゼロ確認

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
