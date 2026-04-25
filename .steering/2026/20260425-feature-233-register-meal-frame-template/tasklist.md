# Tasklist: 食事枠パターン登録・適用機能

## フェーズ概要

| フェーズ | 内容 | DoD |
|---------|------|-----|
| Phase 0 | 既存コードリネーム（BE: FrameEntry → Frame::Entry / FE: mealFrame/ → meal/frame/） | 既存テストが green |
| Phase 1 | DB マイグレーション | テーブル作成・ユーザー確認 |
| Phase 2 | パターン作成（BE + FE） | `/mealframepatterns/new` からパターンが作成できる |
| Phase 3 | パターン一覧（BE + FE） | `/mealframepatterns` でパターン一覧が表示される |
| Phase 4 | パターン更新（BE + FE） | パターン編集ページからパターンを更新できる |
| Phase 5 | パターン削除（BE + FE） | 一覧ページからパターンを削除できる |
| Phase 6 | 枠削除ブロック（BE のみ） | パターン参照中の枠削除がブロックされる |
| Phase 7 | パターン適用（BE + FE） | カレンダー `+` → 枠パターン適用 → FrameCard 表示 |
| Phase 8 | 品質チェック | Rubocop + ESLint green・最終スクリーンショット |
| Phase 9 | ユーザー動作確認 | ユーザーが実際に操作・フィードバック収集 |

---

## Phase 0: 既存コードリネーム（バックエンド + フロントエンド）

**背景:** パターン機能のモジュール階層（`Meal::Frame::*` / `meal/frame/pattern/`）に合わせて、既存コードを整理する。

**DoD:** 既存テスト（バックエンド + フロントエンド）がすべて green

### バックエンド: `Meal::FrameEntry` → `Meal::Frame::Entry`

- [x] `app/domain/business/food/meal/frame_entry/` ディレクトリ以下を `app/domain/business/food/meal/frame/entry/` へ移動
  - `root.rb` を移動
  - `usecase/` 以下のすべてのファイルを移動
- [x] 移動したファイル内のモジュール宣言を `Meal::FrameEntry::*` → `Meal::Frame::Entry::*` に変更
- [x] 全ソースから `Meal::FrameEntry` / `FrameEntry` 参照を検索し更新
  - AR モデル（`meal_frame_entry.rb`）の require・クラス参照
  - GraphQL resolver 内の参照
  - spec ファイル内の参照
- [x] テスト実行: `docker compose exec backend bundle exec rspec` → 全 green 確認

### フロントエンド: `src/features/mealFrame/` → `src/features/meal/frame/`

- [x] `src/features/mealFrame/` ディレクトリ以下をすべて `src/features/meal/frame/` へ移動
- [x] 全ソースから `features/mealFrame` のインポートパスを検索し `features/meal/frame` に更新
  - components 配下の import
  - pages 配下の import
  - hooks / utils 内の import
- [x] テスト実行: `docker compose exec frontend yarn test` → 全 green 確認

---

## Phase 1: DB マイグレーション

**DoD:** `meal_frame_patterns` / `meal_frame_pattern_entries` テーブルが DB に作成される

- [x] マイグレーション作成: `meal_frame_patterns` テーブル
  - `id` (bigint primary key)
  - `user_id` (bigint not null, FK → users)
  - `name` (string not null)
  - `timestamps`
- [x] マイグレーション作成: `meal_frame_pattern_entries` テーブル
  - `id` (bigint primary key)
  - `meal_frame_pattern_id` (bigint not null, FK → meal_frame_patterns, on_delete: :cascade)
  - `meal_frame_id` (bigint not null, FK → meal_frames)
  - `day_offset` (integer not null)
  - `meal_type` (integer not null)
  - `timestamps`
- [x] コンテナ内でマイグレーション実行: `docker compose exec backend rails db:migrate`

> ⚠️ ここで作業を停止し、マイグレーション結果をユーザーに確認する。確認が取れるまで次フェーズへは進まない。

---

## Phase 2: パターン作成（addMealFramePattern mutation が動く）

**DoD:** `/mealframepatterns/new` からパターンが作成でき、DB の `meal_frame_patterns` / `meal_frame_pattern_entries` に保存される

### バックエンド

- [ ] AR モデル: `app/models/meal_frame_pattern.rb` 作成
  - `belongs_to :user`
  - `has_many :meal_frame_pattern_entries, dependent: :destroy`
  - `validates :name, presence: true`
- [ ] AR モデル: `app/models/meal_frame_pattern_entry.rb` 作成
  - `belongs_to :meal_frame_pattern`
  - `belongs_to :meal_frame`
  - `validates :day_offset, numericality: { greater_than: 0 }`
  - `validates :meal_type, presence: true`
- [ ] ドメインモデル: `app/domain/business/food/meal/frame/pattern/root.rb` 作成
  - attributes: `id`, `user_id`, `name`
  - `rename(new_name)`: 名前変更（既存 `Frame::Root#rename` と同命名規則）
  - `set_id(new_id)`: DB 採番後 ID 設定
- [ ] ドメインモデル: `app/domain/business/food/meal/frame/pattern/entry/root.rb` 作成
  - attributes: `id`, `meal_frame_pattern_id`, `day_offset`, `meal_type`, `meal_frame_id`
  - `set_id(new_id)`: DB 採番後 ID 設定
- [ ] spec 作成: `Frame::Pattern::Entry::Usecase::AddCommand` → red
- [ ] `Frame::Pattern::Entry::Usecase::AddCommand` 実装 → green
- [ ] spec 作成: `Frame::Pattern::Usecase::AddCommand` → red
  - 正常作成（エントリあり）
  - 同一 day_offset に複数エントリ（朝・夜の2枠）
- [ ] `Frame::Pattern::Usecase::AddCommand` 実装 → green
  - 1トランザクションで Pattern + 全エントリを作成
- [ ] GraphQL Input 型作成: `MealFramePatternEntryInput`, `MealFramePatternForCreate`
- [ ] spec 作成: `addMealFramePattern` resolver → red
- [ ] `addMealFramePattern` resolver 実装 → green
- [ ] テスト実行: `docker compose exec backend bundle exec rspec` → green 確認

### フロントエンド

- [ ] GraphQL codegen 実行（バックエンドの型変更を反映）
- [ ] `src/features/meal/frame/pattern/addMealFramePatternMutation.ts` 作成
- [ ] `src/features/meal/frame/pattern/useMealFramePattern.ts` hook 作成（`addMealFramePattern` を含む）
- [ ] `src/components/mealFramePattern/MealFramePatternForm.tsx` 作成
  - 名前入力フィールド
  - 日スロット（day_offset）追加ボタン・削除
  - 各日スロットに枠（meal_type + meal_frame_id）追加・削除
  - 「作成する」ボタン → `addMealFramePattern` 呼び出し → `/mealframepatterns` へ遷移
- [ ] `src/app/mealframepatterns/new/page.tsx` 作成（`MealFramePatternForm` を呼ぶ）
- [ ] ナビゲーション: `/mealframepatterns` リンクを追加
- [ ] フロントエンドテスト: `MealFramePatternForm` テスト作成 → red → green
- [ ] テスト実行: `docker compose exec frontend yarn test` → green 確認
- [ ] visual-inspector でスクリーンショット確認: `/mealframepatterns/new`

---

## Phase 3: パターン一覧（mealFramePatterns query が動く）

**DoD:** `/mealframepatterns` で登録済みパターンの一覧が表示される

### バックエンド

- [ ] GraphQL Output 型作成: `MealFramePatternForList`（id, name, entries 含む）
- [ ] spec 作成: `mealFramePatterns` resolver → red
- [ ] `mealFramePatterns` query resolver 実装 → green
  - ログインユーザーのパターンのみ返す
- [ ] テスト実行: `docker compose exec backend bundle exec rspec` → green 確認

### フロントエンド

- [ ] GraphQL codegen 実行
- [ ] `src/features/meal/frame/pattern/mealFramePatternsQuery.ts` 作成
- [ ] `useMealFramePattern.ts` hook に `mealFramePatterns` query を追加
- [ ] `src/components/mealFramePattern/MealFramePatternList.tsx` 作成
  - パターン名・日数（max day_offset）・エントリ数などの一覧表示
  - 各行に「編集」リンク（Phase 4 で実装）・「削除」ボタン（Phase 5 で実装）のプレースホルダ
- [ ] `src/app/mealframepatterns/page.tsx` 作成
- [ ] フロントエンドテスト: `MealFramePatternList` テスト作成 → red → green
- [ ] テスト実行: `docker compose exec frontend yarn test` → green 確認
- [ ] visual-inspector でスクリーンショット確認: `/mealframepatterns`

---

## Phase 4: パターン更新（updateMealFramePattern mutation が動く）

**DoD:** `/mealframepatterns/[id]/edit` からパターン名・エントリを変更できる

### バックエンド

- [ ] spec 作成: `Frame::Pattern::Entry::Usecase::RemoveAllByPatternCommand` → red
- [ ] `Frame::Pattern::Entry::Usecase::RemoveAllByPatternCommand` 実装 → green
- [ ] spec 作成: `Frame::Pattern::Usecase::UpdateCommand` → red
  - 名前変更
  - エントリ全置換（削除後の状態が正しく反映される）
- [ ] `Frame::Pattern::Usecase::UpdateCommand` 実装 → green
  - 1トランザクションで name 更新 + 全エントリ削除 + 新規エントリ全件作成
- [ ] GraphQL Input 型作成: `MealFramePatternForUpdate`
- [ ] spec 作成: `updateMealFramePattern` resolver → red
- [ ] `updateMealFramePattern` resolver 実装 → green
- [ ] テスト実行: `docker compose exec backend bundle exec rspec` → green 確認

### フロントエンド

- [ ] GraphQL codegen 実行
- [ ] `src/features/meal/frame/pattern/updateMealFramePatternMutation.ts` 作成
- [ ] `useMealFramePattern.ts` hook に `updateMealFramePattern` を追加
- [ ] `src/app/mealframepatterns/[id]/edit/page.tsx` 作成
  - `mealFramePatterns` query から該当パターンを取得して `MealFramePatternForm` の初期値にセット
  - 「更新する」ボタン → `updateMealFramePattern` 呼び出し → `/mealframepatterns` へ遷移
- [ ] 一覧ページ（`MealFramePatternList`）に「編集」リンクを有効化
- [ ] フロントエンドテスト: 編集モードの `MealFramePatternForm` テスト更新 → green
- [ ] テスト実行: `docker compose exec frontend yarn test` → green 確認
- [ ] visual-inspector でスクリーンショット確認: `/mealframepatterns/[id]/edit`

---

## Phase 5: パターン削除（deleteMealFramePattern mutation が動く）

**DoD:** パターン一覧ページからパターンを削除でき、DB から `meal_frame_patterns` と `meal_frame_pattern_entries` が消える

### バックエンド

- [ ] spec 作成: `Frame::Pattern::Usecase::RemoveCommand` → red
  - 削除成功
  - `meal_frame_pattern_entries` が cascade delete されること
- [ ] `Frame::Pattern::Usecase::RemoveCommand` 実装 → green
- [ ] spec 作成: `deleteMealFramePattern` resolver → red
- [ ] `deleteMealFramePattern` resolver 実装 → green
- [ ] テスト実行: `docker compose exec backend bundle exec rspec` → green 確認

### フロントエンド

- [ ] GraphQL codegen 実行
- [ ] `src/features/meal/frame/pattern/deleteMealFramePatternMutation.ts` 作成
- [ ] `useMealFramePattern.ts` hook に `deleteMealFramePattern` を追加
- [ ] `MealFramePatternList.tsx` の「削除」ボタンを有効化（confirm ダイアログ → `deleteMealFramePattern` 呼び出し → 一覧再取得）
- [ ] フロントエンドテスト: 削除ボタンのテスト追加 → green
- [ ] テスト実行: `docker compose exec frontend yarn test` → green 確認
- [ ] visual-inspector でスクリーンショット確認: 削除後の `/mealframepatterns`

---

## Phase 6: 枠削除ブロック（パターン参照中の枠は削除できない）

**DoD:** パターンのエントリが参照している `meal_frame` を削除しようとすると、エラーが返り枠は残る

### バックエンド（のみ）

- [ ] spec 更新: `Meal::Frame::Usecase::RemoveCommand` に `MealFramePatternEntry` 参照存在時の削除ブロック spec を追加 → red
- [ ] `Meal::Frame::Usecase::RemoveCommand` を修正: `MealFramePatternEntry` 存在チェックを追加 → green
- [ ] テスト実行: `docker compose exec backend bundle exec rspec` → green 確認

---

## Phase 7: パターン適用（applyMealFramePattern mutation が動く）

**DoD:** カレンダーの `+` ボタン → 「枠パターン適用」タブ → パターン選択 + 開始日入力 → 「適用する」ボタン → 各日に FrameCard が表示される

### バックエンド

- [ ] spec 作成: `applyMealFramePattern` resolver → red
  - 正常ケース: 空の日を含むパターンで正しい日付に MealFrameEntry が作成される
  - パターン所有者チェック: 他ユーザーのパターンは適用不可
- [ ] `applyMealFramePattern` resolver 実装 → green
  - pattern の全エントリを取得
  - 各エントリに対して `Frame::Entry::Usecase::AddCommand` を呼ぶ
  - `date = start_date + (day_offset - 1).days`
- [ ] テスト実行: `docker compose exec backend bundle exec rspec` → green 確認

### フロントエンド

- [ ] GraphQL codegen 実行
- [ ] `src/features/meal/frame/pattern/applyMealFramePatternMutation.ts` 作成
- [ ] `useMealFramePattern.ts` hook に `applyMealFramePattern` を追加
- [ ] `src/components/calendar/calendarComponents/MealIcon/AddMealPattern/index.tsx` 作成
  - `mealFramePatterns` query でパターン一覧を取得・表示
  - 開始日入力（デフォルト = `+` ボタンをクリックした日）
  - 「適用する」ボタン → `applyMealFramePattern` 呼び出し → モーダルを閉じ → `mealsForCalender` 再取得
- [ ] `AddMealIcon.tsx` 修正: 「食事 / 枠 / 枠パターン適用」3択セレクタに拡張
  - 「枠パターン適用」タブ選択時に `AddMealPattern` を表示
- [ ] フロントエンドテスト:
  - `AddMealIcon`: 3択セレクタ切り替えテスト更新 → green
  - `AddMealPattern`: パターン選択・開始日・適用ボタンのテスト → green
- [ ] テスト実行: `docker compose exec frontend yarn test` → green 確認
- [ ] visual-inspector でスクリーンショット確認
  - カレンダー `+` ボタン → 「枠パターン適用」タブが表示される
  - 適用後にカレンダーの各日に FrameCard が表示される

---

## Phase 8: 品質チェック

**DoD:** Rubocop / ESLint が全体で green、最終スクリーンショットで UI に崩れがない

- [ ] Rubocop 実行（バックエンド全体）: `docker compose exec web bundle exec rubocop` → 指摘があれば修正
- [ ] ESLint 実行（フロントエンド全体）: `docker compose exec frontend yarn lint` → 指摘があれば修正
- [ ] visual-inspector で最終スクリーンショット確認
  - `/mealframepatterns` 一覧
  - `/mealframepatterns/new` 作成フォーム
  - `/mealframepatterns/[id]/edit` 編集フォーム
  - カレンダー `+` ボタン → 「枠パターン適用」タブ
  - パターン適用後のカレンダー（FrameCard が各日に表示されること）

---

## Phase 9: ユーザー動作確認

**DoD:** ユーザーが実際に操作し、フィードバックが収集される

- [ ] ユーザーに以下の動作確認を依頼する
  - [ ] `/mealframepatterns/new` から「糖質オフ週（7日分・水曜空）」などのパターンを作成
  - [ ] `/mealframepatterns` で作成したパターンが一覧表示されることを確認
  - [ ] 編集ページからエントリを変更し、更新されることを確認
  - [ ] 不要なパターンを削除できることを確認
  - [ ] カレンダーの `+` ボタン → 「枠パターン適用」 → パターン選択 → 適用 → FrameCard が各日に表示されることを確認
- [ ] フィードバックを収集し、必要であれば `implementation_review.md` に記録

---

## 完了後のアクション

- `feature-64` ロードマップ（`.steering/2026/20260321-feature-64-add-meal-frame/roadmap.md`）の Phase 3 を完了済みとして更新
