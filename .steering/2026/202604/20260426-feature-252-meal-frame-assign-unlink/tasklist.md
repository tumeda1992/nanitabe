# Tasklist: 食事と枠の紐付け解除・既存食事割り当て・+ボタン挙動統一

## フェーズ概要

| フェーズ | 内容 | DoD |
|---------|------|-----|
| Phase 1 | ① BE: 枠解除バックエンド | `unassignMealFromFrameEntry` で meal_id が null になる（spec green） |
| Phase 2 | ① FE: DishCard 枠解除ボタン | DishCard「枠解除」クリックで枠が解除されカレンダーが更新される |
| Phase 3 | ② BE: 既存食事割り当てバックエンド | `fillMealFrameEntry` で meal_id がセットされる（spec green） |
| Phase 4 | ② FE: FrameCard 既存食事割り当て | FrameCard から既存食事を選択して割り当てられる |
| Phase 5 | ③ FE: `+`ボタン挙動統一 | 空エリアの `+` クリックで3タブモーダルが開く |
| Phase 6 | 品質チェック | Rubocop / ESLint green・最終スクリーンショット確認 |
| Phase 7 | ユーザー動作確認 | ユーザーが実際に操作・フィードバック収集 |

---

## Phase 1: ① BE — 枠解除バックエンド

**DoD:** `unassignMealFromFrameEntry` mutation を呼ぶと `meal_frame_entries.meal_id` が NULL になる（RSpec green）

- [x] `Frame::Entry::Root#unassign_meal` メソッド追加
  - `meal_id = nil` をセットするのみ
  - 命名根拠: `assign_meal` の逆操作として対称性を保つ
- [x] spec 作成: `Frame::Entry::Usecase::UnassignMealCommand` → red
  - 正常: meal_id が nil になる
  - 異常: 存在しない meal_frame_entry_id（RecordNotFound）
- [x] `Frame::Entry::Usecase::UnassignMealCommand` 実装 → green
  - attributes: `user_id`, `meal_frame_entry_id`
  - `build_existing_root_from_id` → `root.unassign_meal` → `persist`
- [x] spec 作成: `unassignMealFromFrameEntry` resolver → red
  - 正常: meal_id が nil になる
  - 異常: 他ユーザーの frame_entry_id（エラーになること）
- [x] `Mutations::Meal::FrameEntry::UnassignMealFromFrameEntry` 実装 → green
  - argument: `frame_entry_id: Int!`
  - field: `frame_entry_id: Int!`
- [x] `mutation_type.rb` に `field :unassign_meal_from_frame_entry` を追加
- [x] テスト実行: `docker compose exec backend bundle exec rspec` → green 確認

---

## Phase 2: ① FE — DishCard 枠解除ボタン

**DoD:** DishCard のアクションパネルで「枠解除」をクリックすると枠が解除され、DishCard から枠名ラベルが消え FrameCard が再出現する

- [x] GraphQL codegen 実行: `docker compose exec frontend yarn codegen`（schema.json / graphql.ts 更新）
- [x] `frontend/src/features/meal/frame/unassignMealFromFrameEntryMutation.ts` 新規作成
  - mutation: `unassignMealFromFrameEntry(frameEntryId: Int!)`
- [x] `useMealFrame.ts` に `unassignMealFromFrameEntry` を追加
- [x] spec 更新: `DishCard` に枠解除ボタンのテスト追加 → red
  - `mealFrameEntryId` あり → 「枠解除」ボタンが表示される
  - `mealFrameEntryId` なし → 「枠解除」ボタンが表示されない
  - 「枠解除」クリック → confirm → `unassignMealFromFrameEntry` が呼ばれる
- [x] `DishCard` に「枠解除」ActionBtn 追加 → green
  - 表示条件: `meal.mealFrameEntryId != null`
  - アイコン: `Unlink`（lucide-react）
  - ラベル: `枠解除`
  - クリック: `confirm` → `unassignMealFromFrameEntry({ frameEntryId: meal.mealFrameEntryId })` → `onChanged()`
- [x] テスト実行: `docker compose exec frontend yarn test` → green 確認
- [x] visual-inspector でスクリーンショット確認
  - 枠付き DishCard のアクションパネルに「枠解除」ボタンが表示されること
  - 枠なし DishCard には「枠解除」ボタンが表示されないこと
  > 確認日時: 2026-04-26 10:35
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260426-feature-252-meal-frame-assign-unlink/phase2/result.md
  >
  > 項目1: 枠付き DishCard のアクションパネルに「枠解除」ボタンが表示されること ✅
  >   期待値: mealFrameEntryId があるDishCardのアクションパネルに「枠解除」ボタンが表示される
  >   結果: 「焼肉・塊肉」という枠名が表示された「餃子」DishCardのアクションパネルに「枠解除」ボタンが正しく表示された
  >
  > 項目2: 枠なし DishCard のアクションパネルに「枠解除」ボタンが表示されないこと ✅
  >   期待値: mealFrameEntryId がないDishCardのアクションパネルに「枠解除」ボタンが表示されない
  >   結果: 「長距離ウォーキングついでにご飯」DishCardのアクションパネルに「枠解除」ボタンが表示されなかった

---

## Phase 3: ② BE — 既存食事割り当てバックエンド

**DoD:** `fillMealFrameEntry` mutation を呼ぶと `meal_frame_entries.meal_id` に指定した meal_id がセットされる（RSpec green）

- [x] spec 作成: `fillMealFrameEntry` resolver → red
  - 正常: meal_id がセットされる
  - 異常: 他ユーザーの frame_entry_id
  - 異常: 他ユーザーの meal_id
- [x] `Mutations::Meal::FrameEntry::FillMealFrameEntry` 実装 → green
  - arguments: `frame_entry_id: Int!`, `meal_id: Int!`
  - resolver → `FillWithMealCommand.call(user_id:, meal_frame_entry_id: frame_entry_id, meal_id:)`
  - field: `frame_entry_id: Int!`
- [x] `mutation_type.rb` に `field :fill_meal_frame_entry` を追加
- [x] テスト実行: `docker compose exec backend bundle exec rspec` → green 確認

---

## Phase 4: ② FE — FrameCard 既存食事割り当て

**DoD:** FrameCard をクリックすると2タブモーダルが開き、「既存の食事を割り当て」タブから同日の枠未割り当て食事を選んで割り当てられる

- [x] GraphQL codegen 実行（Phase 3 の mutation を反映）
- [x] `frontend/src/features/meal/frame/fillMealFrameEntryMutation.ts` 新規作成
  - mutation: `fillMealFrameEntry(frameEntryId: Int!, mealId: Int!)`
- [x] `useMealFrame.ts` に `fillMealFrameEntry` を追加
- [x] `DateCard` に `unlinkedMeals` の算出と `FrameCard` への受け渡しを追加
  - `const unlinkedMeals = meals.filter(m => !m.mealFrameEntryId);`
  - `<FrameCard unlinkedMeals={unlinkedMeals} ...>`
- [x] spec 更新: `FrameCard` にタブ切り替えと割り当てのテスト追加 → red
  - Tab 1「新しく食事を登録」が表示される
  - `unlinkedMeals` ありのとき Tab 2「既存の食事を割り当て」が表示される
  - `unlinkedMeals` 空のとき Tab 2 に「割り当て可能な食事がありません」が表示される
  - 食事を選択して「割り当てる」→ `fillMealFrameEntry` が呼ばれる
- [x] `FrameCard` のモーダルを2タブ化 → green
  - `unlinkedMeals: MealForCalender[]` prop 追加
  - Tab 1: 「新しく食事を登録」（既存 AddMeal）
  - Tab 2: 「既存の食事を割り当て」（unlinkedMeals リスト → 選択 → `fillMealFrameEntry`）
  - 空リスト時: 「割り当て可能な食事がありません」メッセージ
- [x] テスト実行: `docker compose exec frontend yarn test` → green 確認
- [x] visual-inspector でスクリーンショット確認
  - FrameCard クリックで2タブモーダルが開くこと
  - 「既存の食事を割り当て」タブに食事リストが表示されること
  > 確認日時: 2026-04-26 10:55
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260426-feature-252-meal-frame-assign-unlink/phase4/result.md
  >
  > 項目1: FrameCard クリックで2タブモーダルが開くこと ✅
  >   期待値: 2タブ（新しく食事を登録・既存の食事を割り当て）のモーダルが開く
  >   結果: 2タブモーダルが正常に表示された
  >
  > 項目2: 「既存の食事を割り当て」タブに食事リストが表示されること ✅
  >   期待値: 同日の枠未割り当て食事リストが表示される
  >   結果: 「ディスコのきゅうり」が表示された

---

## Phase 5: ③ FE — `+`ボタン挙動統一

**DoD:** 食事がない日の空エリアの `+` をクリックすると、日付横の `+` と同じ3タブ（食事/枠/枠パターン適用）モーダルが開く

**方針:** 3タブロジックを `AddMealTabs` コンポーネントに抽出し、AddMealIcon と DateCard の両方から使う。AddMealIcon への props 追加なし。DateCard の点線エリア・`onClick` は変えない。

- [x] spec 作成: `AddMealTabs` のテスト → red
  - 初期表示: 「食事」タブが選択され AddMeal が表示される
  - 「枠」タブクリック: AddMealFrame が表示される
  - 「枠パターン適用」タブクリック: AddMealPattern が表示される
- [x] `AddMealTabs` コンポーネント新規作成 → green
  - props: `defaultDate: string`, `onAddSucceeded: () => void`
  - タブ切り替え state（`'meal' | 'frame' | 'pattern'`）と子コンポーネント出し分けのみを持つ
- [x] `AddMealIcon` の FullScreenModal 内部を `AddMealTabs` に差し替え
  - AddMealIcon の props・インターフェースは変えない
- [x] spec 更新: `DateCard` の空エリアクリックで3タブモーダルが開くことをテスト → red
- [x] `DateCard` の FullScreenModal 内部を `AddMealTabs` に差し替え → green
  - 点線エリアの `<button onClick={openModal}>+</button>` および `data-testid` は一切変えない
- [x] テスト実行: `docker compose exec frontend yarn test` → green 確認
- [x] visual-inspector でスクリーンショット確認
  - 空エリアの `+` クリックで3タブモーダルが開くこと
  - 日付横の `+` と同じ3タブ構成が表示されること
  - 点線エリアの見た目（デザイン・配置）に変化がないこと
  > 確認日時: 2026-04-26 11:20
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260426-feature-252-meal-frame-assign-unlink/phase5/result.md
  >
  > 項目1: AddMealIcon（日付横の+）クリックで3タブモーダルが表示されること ✅
  >   期待値: 3タブ（食事/枠/枠パターン適用）モーダルが開く
  >   結果: AddMealTabs 差し替え後も3タブが正常表示された（02_addmealicon_modal.png）
  >
  > 項目2: 空エリアの + クリックで3タブモーダルが開くこと ✅（spec で確認）
  >   期待値: 点線エリアの+クリックで3タブモーダルが開く
  >   結果: 実環境に空エリアなし（全日程に食事あり）。spec「空エリアをクリックすると3タブモーダルが開くこと」が green で確認済み
  >
  > 項目3: 点線エリアの見た目に変化がないこと ✅（spec で確認）
  >   期待値: data-testid・onClick・デザインに変化なし
  >   結果: DateCard 既存 spec が全て green で確認済み

---

## Phase 6: 品質チェック

**DoD:** Rubocop / ESLint が全体で green、最終スクリーンショットで UI に崩れがない

- [x] Rubocop 実行: `docker compose exec backend bundle exec rubocop` → no offenses
- [x] ESLint 実行: `docker compose exec frontend yarn lint` → no errors
- [x] visual-inspector で最終スクリーンショット確認
  - 枠付き DishCard: アクションパネルに「枠解除」が表示される
  - FrameCard: クリックで2タブモーダルが表示される
  - 空エリア `+`: クリックで3タブモーダルが表示される
  > 確認日時: 2026-04-26 11:35
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260426-feature-252-meal-frame-assign-unlink/phase6/result.md
  >
  > 項目1: 枠付き DishCard のアクションパネルに「枠解除」が表示されること ✅
  >   期待値: mealFrameEntryId がある DishCard に「枠解除」ボタンが表示される
  >   結果: 「焼肉・塊肉」フレームの「餃子」DishCard のアクションパネルに「枠解除」が正常表示された
  >
  > 項目2: FrameCard クリックで2タブモーダルが表示されること ✅
  >   期待値: 2タブ（新しく食事を登録・既存の食事を割り当て）のモーダルが開く
  >   結果: 「ホルモン」FrameCard クリックで2タブモーダルが正常表示された
  >
  > 項目3: 空エリア + クリックで3タブモーダルが表示されること ✅（spec 確認）
  >   期待値: 点線エリアの+クリックで3タブモーダルが開く
  >   結果: 実環境に空エリアなし。AddMealIcon での確認とspec（173/173 passed）で代替確認済み

---

## Phase 7: ユーザー動作確認

**DoD:** ユーザーが実際に操作し、フィードバックが収集される

> ⚠️ この確認が完了するまでコミット・push は行わない

- [x] ユーザーに以下の動作確認を依頼する
  - [x] ① 枠付き DishCard → アクションパネル → 「枠解除」→ 枠が外れ FrameCard が再出現することを確認
  - [x] ② FrameCard クリック → 2タブモーダル → 「既存の食事を割り当て」→ 食事を選択して割り当てられることを確認
  - [x] ③ 食事がない日の空エリア `+` クリック → 3タブモーダル（食事/枠/枠パターン適用）が開くことを確認
- [x] フィードバックを収集し、必要であれば `implementation_review.md` に記録

---

## 完了後のアクション

- コミット・push・PR 作成
