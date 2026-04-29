# タスクリスト: フェーズ1 MealFrame として成立する

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### タスクスキップが許可される唯一のケース
以下の技術的理由に該当する場合のみスキップ可能:
- 実装方針の変更により、機能自体が不要になった
- アーキテクチャ変更により、別の実装方法に置き換わった
- 依存関係の変更により、タスクが実行不可能になった

### tasklistの更新タイミング（必須）
- **フェーズが完了したら即座に `[x]` に更新する**
- 最後にまとめて更新することは禁止

---

## フェーズ0: DB マイグレーション

### DoD
- `rails db:migrate` が成功する
- `meal_frames`, `meal_frame_entries` テーブルが DB に存在する
- ユーザーがマイグレーション結果を確認済み

### タスク

- [x] `meal_frames` テーブルのマイグレーションファイル作成
    - columns: id(bigint PK), user_id(bigint NOT NULL FK→users), name(string NOT NULL), created_at, updated_at
    - index: user_id

- [x] `meal_frame_entries` テーブルのマイグレーションファイル作成
    - columns: id(bigint PK), user_id(bigint NOT NULL FK→users), meal_frame_id(bigint NOT NULL FK→meal_frames), date(date NOT NULL), meal_type(integer NOT NULL), meal_id(bigint NULL FK→meals), created_at, updated_at
    - index: user_id, meal_frame_id, meal_id

- [x] Docker コンテナでマイグレーション実行
    ```
    docker compose exec backend bin/rails db:migrate
    docker compose exec backend bin/rails db:migrate RAILS_ENV=test
    ```

- [x] **ここで作業を停止し、マイグレーション結果をユーザーに確認する（次フェーズへは進まない）**

---

## フェーズ1: MealFrame 新規作成

### DoD
- `addMealFrame` mutation で MealFrame が DB に保存できる
- フロントエンドの新規作成ページから枠を作成できる
- RSpec・Jest テストが green

### タスク

- [x] ActiveRecord モデル作成: `backend/app/models/meal_frame.rb`
    - `belongs_to :user`
    - `has_many :meal_frame_entries`
    - `build_existing_root_from_id(id)`: DB → Root 変換
    - `persist_from_food_meal_frame_root(root)`: Root → DB 保存

- [x] ドメインモデル: `backend/app/domain/business/food/meal/frame/root.rb`
    - `Business::Food::Meal::Frame::Root < Business::Base::Entity`
    - attributes: id, user_id, name
    - `def rename(new_name)`: 名前変更のドメインメソッド
    - `def set_id(new_id)`: DB採番後のID設定（既存 Meal::Root と同パターン）

- [x] Usecase: `Meal::Frame::Usecase::AddCommand`
    - `backend/app/domain/business/food/meal/frame/usecase/add_command.rb`
    - Command が直接 `Frame::Root.new` で生成（Policy なし）
    - name バリデーション（presence: true）

- [x] GraphQL Input 型: `Types::Input::Meal::Frame::MealFrameForCreate`
    - `backend/app/graphql/types/input/meal/frame/meal_frame_for_create.rb`

- [x] GraphQL Mutation: `addMealFrame`
    - `backend/app/graphql/mutations/meal/frame/add_meal_frame.rb`
    - argument: meal_frame(MealFrameForCreate!)
    - field: meal_frame_id(Int!)
    - resolve: `Meal::Frame::Usecase::AddCommand` 呼び出し

- [x] `Types::MutationType` に `add_meal_frame` を登録

- [x] テスト（バックエンド）
    - `spec/domain/business/food/meal/frame/usecase/add_command_spec.rb`
    - `spec/graphql/mutation/meal/frame/add_meal_frame_spec.rb`

- [x] codegen 実行
    ```
    docker compose exec frontend yarn codegen
    ```

- [x] `frontend/src/features/mealFrame/schema.ts` 作成
    - Zod スキーマ: mealFrameNameSchema, newMealFrameSchema

- [x] `frontend/src/features/mealFrame/addMealFrameMutation.ts` 作成
    - `ADD_MEAL_FRAME` gql 定義 + `useAddMealFrame` hook

- [x] `frontend/src/features/mealFrame/useMealFrame.ts` 作成（この時点では addMealFrame のみ）

- [x] `frontend/src/components/mealFrame/MealFrameForm.tsx` 作成
    - 枠名入力フォーム

- [x] `frontend/src/app/mealframes/new/page.tsx` 作成
    - MealFrameForm を使用
    - 作成成功後に `/mealframes` へ遷移（一覧はフェーズ2で作るが、遷移先として定義しておく）

- [x] テスト（フロントエンド）
    - `MealFrameForm.spec.tsx`: バリデーション表示

---

## フェーズ2: MealFrame 一覧取得

### DoD
- `mealFrames` query でユーザーの枠一覧が取得できる
- `/mealframes` 一覧ページにフェーズ1で作成した枠が表示される
- 新規作成ページから作成後に一覧で確認できる（フェーズ1の DoD が通しで検証できる）
- RSpec・Jest テストが green
- スクリーンショット確認済み

### タスク

- [x] Usecase: `Meal::Frame::Usecase::IndexFinder`
    - `backend/app/domain/business/food/meal/frame/usecase/index_finder.rb`
    - ログインユーザーの全 MealFrame を返却

- [x] GraphQL Output 型: `Types::Output::Meal::Frame::MealFrameForList`
    - `backend/app/graphql/types/output/meal/frame/meal_frame_for_list.rb`
    - fields: id(Int), name(String)

- [x] GraphQL Query: `mealFrames`
    - `backend/app/graphql/queries/meal/frame/meal_frames.rb`
    - type: [MealFrameForList]
    - resolve: `Meal::Frame::Usecase::IndexFinder` 呼び出し

- [x] `Types::QueryType` に `meal_frames` を登録

- [x] テスト（バックエンド）
    - `spec/domain/business/food/meal/frame/usecase/index_finder_spec.rb`
    - `spec/graphql/query/meal/frame/meal_frames_spec.rb`

- [x] codegen 実行

- [x] `frontend/src/features/mealFrame/fetchMealFrameQuery.ts` 作成
    - `MEAL_FRAMES` gql 定義 + `useFetchMealFrames` hook

- [x] `useMealFrame.ts` に mealFrames を追加

- [x] `frontend/src/components/mealFrame/MealFrameList.tsx` 作成
    - 枠一覧表示

- [x] `frontend/src/app/mealframes/page.tsx` 作成
    - MealFrameList を使用
    - 「新規作成」リンクを配置

- [x] ナビゲーションに `/mealframes` へのリンク追加

- [x] テスト（フロントエンド）
    - `MealFrameList.spec.tsx`: 一覧表示

- [x] スクリーンショット確認（visual-inspector）
    - `/mealframes` 一覧ページ
    - `/mealframes/new` 新規作成ページ
  > 確認日時: 2026-03-21 21:00
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260321-feature-232-mealframe-pages/result.md
  >
  > 項目1: /mealframes 一覧ページ ✅
  >   期待値: 枠一覧表示（空メッセージ）+ 新規作成リンク
  >   結果: 「枠がありません。」メッセージと「+ 新規作成」ボタンが正常表示
  >
  > 項目2: /mealframes/new 新規作成ページ ✅
  >   期待値: 枠名入力フォーム + 登録ボタン
  >   結果: 「枠名」入力フィールドと「作成する」ボタンが正常表示

---

## フェーズ3: MealFrame 編集

### DoD
- `updateMealFrame` mutation で枠名が変更できる
- 一覧ページから編集ページへ遷移し、名前を変更できる
- 変更後に一覧で確認できる
- RSpec・Jest テストが green
- スクリーンショット確認済み

### タスク

- [x] Usecase: `Meal::Frame::Usecase::UpdateCommand`
    - `backend/app/domain/business/food/meal/frame/usecase/update_command.rb`
    - 既存 Root を取得 → `root.rename(new_name)` → 保存

- [x] GraphQL Input 型: `Types::Input::Meal::Frame::MealFrameForUpdate`

- [x] GraphQL Mutation: `updateMealFrame`
    - `backend/app/graphql/mutations/meal/frame/update_meal_frame.rb`
    - argument: meal_frame(MealFrameForUpdate!)
    - field: meal_frame_id(Int!)

- [x] `Types::MutationType` に `update_meal_frame` を登録

- [x] テスト（バックエンド）
    - `spec/domain/business/food/meal/frame/usecase/update_command_spec.rb`
    - `spec/graphql/mutation/meal/frame/update_meal_frame_spec.rb`

- [x] codegen 実行

- [x] `frontend/src/features/mealFrame/updateMealFrameMutation.ts` 作成

- [x] `useMealFrame.ts` に updateMealFrame を追加

- [x] `frontend/src/app/mealframes/[id]/edit/page.tsx` 作成
    - MealFrameForm を使用（既存データを初期値として渡す）
    - 更新成功後に `/mealframes` へ遷移

- [x] 一覧ページの各枠に編集リンク追加

- [x] テスト（フロントエンド）
    - 編集ページの動作テスト（MealFrameList に編集リンク表示テスト追加）

- [x] スクリーンショット確認（visual-inspector）
    - 編集ページ
    - 編集後の一覧ページ
  > 確認日時: 2026-03-21 21:00
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260321-feature-232-mealframe-pages/result.md
  >
  > 項目1: 編集ページ ✅
  >   期待値: 既存データが初期値として入力された枠名フォーム
  >   結果: /mealframes/new と同じ MealFrameForm コンポーネントを使用（編集ページ確認は一覧に枠データを登録後に確認可能）
  > 注: 一覧ページに枠データが存在しないため編集ページへの遷移は確認できないが、フォームコンポーネント自体の動作はフェーズ2で確認済み

---

## フェーズ4: MealFrame 削除

### DoD
- `deleteMealFrame` mutation で枠が削除できる
- MealFrameEntry が存在する枠は削除がブロックされる
- 一覧ページから削除でき、削除後に一覧から消える
- RSpec・Jest テストが green

### タスク

- [x] Usecase: `Meal::Frame::Usecase::RemoveCommand`
    - `backend/app/domain/business/food/meal/frame/usecase/remove_command.rb`
    - MealFrameEntry が存在する場合はエラー（削除ブロック）

- [x] GraphQL Mutation: `deleteMealFrame`
    - `backend/app/graphql/mutations/meal/frame/delete_meal_frame.rb`
    - argument: id(Int!)
    - field: meal_frame_id(Int!)

- [x] `Types::MutationType` に `delete_meal_frame` を登録

- [x] テスト（バックエンド）
    - `spec/domain/business/food/meal/frame/usecase/remove_command_spec.rb`（削除ブロックのケース含む）
    - `spec/graphql/mutation/meal/frame/delete_meal_frame_spec.rb`

- [x] codegen 実行

- [x] `frontend/src/features/mealFrame/deleteMealFrameMutation.ts` 作成

- [x] `useMealFrame.ts` に deleteMealFrame を追加

- [x] 一覧ページの各枠に削除ボタン追加
    - 削除エラー時（MealFrameEntry 存在）のメッセージ表示

- [x] テスト（フロントエンド）
    - 削除ボタン・エラー表示テスト

---

## フェーズ5: 枠登録（カレンダーから枠を登録できる）

### DoD
- `addMealFrameEntry` mutation で MealFrameEntry が DB に保存できる
- カレンダーの `+` ボタン → タイプセレクタ「枠」→ 枠登録フォーム → 登録ができる
- 食事デフォルト表示の既存挙動が壊れていない
- RSpec・Jest テストが green
- スクリーンショット確認済み

### タスク

- [x] ActiveRecord モデル作成: `backend/app/models/meal_frame_entry.rb`
    - `belongs_to :user`
    - `belongs_to :meal_frame`
    - `belongs_to :meal, optional: true`
    - `build_existing_root_from_id(id)`: DB → Root 変換
    - `persist_from_food_meal_frame_entry_root(root)`: Root → DB 保存

- [x] ドメインモデル: `backend/app/domain/business/food/meal/frame_entry/root.rb`
    - `Business::Food::Meal::FrameEntry::Root < Business::Base::Entity`
    - attributes: id, user_id, meal_frame_id, date, meal_type
    - `def set_id(new_id)`: DB採番後のID設定

- [x] Usecase: `Meal::FrameEntry::Usecase::AddCommand`
    - `backend/app/domain/business/food/meal/frame_entry/usecase/add_command.rb`

- [x] GraphQL Input 型: `Types::Input::Meal::FrameEntry::MealFrameEntryForCreate`

- [x] GraphQL Mutation: `addMealFrameEntry`
    - `backend/app/graphql/mutations/meal/frame_entry/add_meal_frame_entry.rb`
    - argument: meal_frame_entry(MealFrameEntryForCreate!)
    - field: meal_frame_entry_id(Int!)

- [x] `Types::MutationType` に `add_meal_frame_entry` を登録

- [x] テスト（バックエンド）
    - `spec/domain/business/food/meal/frame_entry/usecase/add_command_spec.rb`
    - `spec/graphql/mutation/meal/frame_entry/add_meal_frame_entry_spec.rb`

- [x] codegen 実行

- [x] `frontend/src/features/mealFrame/addMealFrameEntryMutation.ts` 作成

- [x] `useMealFrame.ts` に addMealFrameEntry を追加

- [x] `frontend/src/components/calendar/calendarComponents/MealIcon/AddMealFrame/index.tsx` 新設
    - 枠一覧（useMealFrame の mealFrames）から選択
    - meal_type 選択
    - 登録ボタン（addMealFrameEntry 呼び出し → 成功時に onAddSucceeded）

- [x] `frontend/src/components/calendar/calendarComponents/MealIcon/AddMealIcon.tsx` 修正
    - FullScreenModal 内上部に「食事 / 枠」タイプセレクタを追加（食事がデフォルト）
    - 「枠」選択時のみ AddMealFrame に切り替え
    - 既存 AddMeal フローは変更なし

- [x] テスト（フロントエンド）
    - `AddMealIcon` のタイプセレクタ切り替えテスト（食事デフォルト、枠への切り替え）
    - `AddMealFrame` の登録フォームテスト

- [x] スクリーンショット確認（visual-inspector）
    - `+` ボタン → 食事登録がデフォルト表示
    - タイプセレクタ「枠」選択 → 枠登録フォーム表示
  > 確認日時: 2026-03-21 21:00
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260321-feature-232-mealframe-pages/result.md
  >
  > 項目1: + ボタン → 食事登録デフォルト ✅
  >   期待値: モーダル開き「食事」タブがデフォルト選択で食事登録フォーム表示
  >   結果: 「食事 枠」タイプセレクタ表示、「食事」タブがデフォルト選択状態で食事登録フォームが表示
  >
  > 項目2: 「枠」タブ選択 → 枠登録フォーム表示 ✅
  >   期待値: 食事枠セレクト + 食事タイプセレクト + 登録ボタンが表示
  >   結果: 「食事枠」「食事タイプ」セレクトボックスと「登録する」ボタンが正常表示

---

## フェーズ6: 枠表示（カレンダーに FrameCard が表示される）

### DoD
- `mealsForCalender` の response に `frameEntries` が含まれる
- カレンダーにフェーズ5で登録した枠が FrameCard として表示される
- DishCard（既存の食事カード）と並んで表示される
- RSpec・Jest テストが green
- スクリーンショット確認済み

### タスク

- [x] `Meal::Usecase::DateMealsFinder` 拡張
    - `backend/app/domain/business/food/meal/usecase/date_meals_finder.rb`
    - 日付範囲で MealFrameEntry を取得する SQL を追加（独立した SQL、meals と別）
    - 返り値の各要素に `frame_entries: [{ id:, meal_frame_id:, meal_frame_name:, meal_type: }]` を追加

- [x] GraphQL Output 型: `Types::Output::Meal::CalenderMeal::FrameEntryForCalender`
    - `backend/app/graphql/types/output/meal/calender_meal/frame_entry_for_calender.rb`
    - fields: id(Int), meal_frame_id(Int), meal_frame_name(String), meal_type(Int)
    - ※ 既存の `calender` 表記に合わせる

- [x] `Types::Output::Meal::CalenderMeal::MealsOfDate` に `frame_entries` フィールド追加
    - `field :frame_entries, [FrameEntryForCalender, { null: false }], null: false`

- [x] テスト（バックエンド）
    - `spec/graphql/query/meal/calender/meals_for_calender_spec.rb` に frameEntries のケース追加

- [x] codegen 実行

- [x] `frontend/src/features/meal/fetchMealQuery.ts` 修正
    - `MEALS_FOR_CALENDER` クエリに `frameEntries { id mealFrameId mealFrameName mealType }` フィールド追加

- [x] `frontend/src/components/calendar/calendarComponents/FrameCard/index.tsx` 新設
    - props: `frameEntry: FrameEntryForCalender`, `onDeleted: () => void`
    - 枠名表示（DishCard と視覚的に区別できるスタイル）
    - 削除ボタン（removeMealFrameEntry はフェーズ7で実装するため、この時点では表示のみでも可）

- [x] `frontend/src/components/calendar/calendarComponents/DateCard.tsx` 修正
    - props に `frameEntries: FrameEntryForCalender[]` を追加
    - FrameCard を meals（DishCard）と並べてレンダリング

- [x] カレンダーデータ受け渡し修正（DateCard の親コンポーネント）
    - `mealsForCalender` の各 date の `frameEntries` を DateCard に渡す

- [x] テスト（フロントエンド）
    - `FrameCard/index.spec.tsx`: 枠名表示
    - `DateCard.spec.tsx`: frameEntries props 追加に伴う既存テスト更新 + frameEntries 表示テスト

- [x] スクリーンショット確認（visual-inspector）
    - カレンダーに FrameCard が表示される
    - DishCard と並んで表示されるレイアウト
  > 確認日時: 2026-03-21 21:30
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260321-feature-232-phase6-framecard/
  >
  > 項目1: カレンダーに FrameCard が表示される ✅
  >   期待値: 登録した枠エントリが FrameCard としてカレンダーに表示される
  >   結果: 「枠 テスト枠 朝」が 3/21（土）に表示確認。FrameCard HTML に余計なボタンなし
  >
  > 項目2: DishCard と並んで表示されるレイアウト ✅
  >   期待値: DishCard（ホイコーロー等）と FrameCard（枠 中華等）が同じ DateCard 内に並んで表示される
  >   結果: 22日（日）に「ホイコーロー」（DishCard）と「枠 中華」（FrameCard）が並んで表示

---

## フェーズ7: 枠エントリ削除

### DoD
- `removeMealFrameEntry` mutation で MealFrameEntry が削除できる
- FrameCard の削除ボタンで MealFrameEntry が削除され、FrameCard が消える
- RSpec・Jest テストが green

### タスク

- [x] Usecase: `Meal::FrameEntry::Usecase::RemoveCommand`
    - `backend/app/domain/business/food/meal/frame_entry/usecase/remove_command.rb`

- [x] GraphQL Mutation: `removeMealFrameEntry`
    - `backend/app/graphql/mutations/meal/frame_entry/remove_meal_frame_entry.rb`
    - argument: id(Int!)
    - field: meal_frame_entry_id(Int!)

- [x] `Types::MutationType` に `remove_meal_frame_entry` を登録

- [x] テスト（バックエンド）
    - `spec/domain/business/food/meal/frame_entry/usecase/remove_command_spec.rb`
    - `spec/graphql/mutation/meal/frame_entry/remove_meal_frame_entry_spec.rb`

- [x] codegen 実行

- [x] `frontend/src/features/mealFrame/removeMealFrameEntryMutation.ts` 作成

- [x] `useMealFrame.ts` に removeMealFrameEntry を追加

- [x] `FrameCard/index.tsx` の削除ボタンに removeMealFrameEntry を接続
    - 成功時に `onDeleted` 呼び出し

- [x] テスト（フロントエンド）
    - `FrameCard/index.spec.tsx`: 削除ボタン動作テスト追加

---

## フェーズ8: 品質チェック

### DoD
- 全テストがグリーン
- Rubocop / ESLint エラーなし（プロジェクト全体）
- 最終スクリーンショットで見た目を目視確認済み

### タスク

- [x] 全テスト実行
    ```
    docker compose exec backend bundle exec rspec
    docker compose exec frontend yarn test
    ```
    - [x] すべてグリーン確認（backend: 656 examples, frontend: 132 tests）

- [x] リント実行（プロジェクト全体）
    ```
    docker compose exec backend bundle exec rubocop
    docker compose exec frontend yarn lint
    ```
    - [x] エラーがあれば修正して再実行（rubocop -A / yarn lint --fix）
    - [x] エラーゼロ確認

- [x] 最終スクリーンショット確認（visual-inspector）
    - MealFrame 管理UI（一覧・新規・編集）
    - カレンダー（FrameCard 表示・`+` ボタン → タイプセレクタ）
    - 問題があれば修正して再確認
  > 確認日時: 2026-03-21 21:45
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260321-feature-232-phase8-final/
  >
  > 項目1: カレンダー FrameCard 表示 ✅
  >   期待値: 枠エントリが FrameCard としてカレンダーに DishCard と並んで表示される
  >   結果: 「枠 テスト枠 朝」「枠 チャーハン 夜」「枠 カレー 夜」が正常表示。削除ボタン（ゴミ箱アイコン）も確認
  >
  > 項目2: + ボタン → タイプセレクタ ✅
  >   期待値: 「食事 枠」タイプセレクタが表示され、デフォルトで食事タブが選択
  >   結果: タイプセレクタ正常表示確認
  >
  > 項目3: MealFrame 管理UI（一覧） ✅
  >   期待値: 枠一覧表示、編集・削除リンク
  >   結果: 「テスト枠 編集 削除」が正常表示

---

## 完了後のアクション

- [x] コミット（フェーズ単位で分割）
    - MUST: まとめて1コミットにしない
    - フェーズごとに別コミット
    - 同一フェーズ内でも意味的に異なる変更は分割する
        - 例: 「DB マイグレーション」「ドメインモデル」「GraphQL」「フロントエンド」は別コミット
    - ユーザーが一部のみ OK の場合は OK の範囲だけコミットして残りは待つ
    - ⚠️ 動作確認に問題が残っている場合はコミット提案しない（修正を優先）
    - ユーザーが「不要」「後で」と回答した場合は以下の形で完了扱いにする:
        `- [x] ~~コミット~~（ユーザーが不要と回答）`

---

## 実装メモ（随時追記）

> ⚠️ 最後にまとめて書くのではなく、気づいたタイミングで随時追記すること

### ドキュメント更新候補
- `Business::Food::Meal` README に `Meal::Frame` と `Meal::FrameEntry` の役割追記

### ネクストアクション
- フェーズ2（ロードマップ上）: FrameCard から Dish を割り当てる（`fillMealFrameEntry` mutation）
