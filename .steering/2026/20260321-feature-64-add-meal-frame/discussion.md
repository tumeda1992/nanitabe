# Discussion Log

## 議題1: `addMealFromFrameEntry` は独立した GraphQL Mutation が必要か

### 論点

design.md では `addMealFromFrameEntry` を独立した Mutation として定義していたが、ユーザーから「`addMeal` にオプションで `frame_entry_id` を追加するだけで良いのでは」という提案があった。

### 検討

`addMealFromFrameEntry` を独立 Mutation にした場合、「どんな形で dish を用意するか」という既存の3バリエーション（既存dish / 新規dish / 新規dish+source）すべてにかかってくる。結果として `addMealFromFrameEntry` / `addMealFromFrameEntryWithNewDish` / `addMealFromFrameEntryWithNewDishAndNewSource` の3 Mutation が追加され、合計6になる。

`frame_entry_id` を既存 Mutation にオプション追加する形なら Mutation 数は増えない。

### 結論

**GraphQL 層では `frame_entry_id`(optional) を既存の `addMeal` 系 3 Mutation に追加する形を採用する。**

独立 Mutation にすることで Mutation 数が爆発するリスクを避ける。フロントエンド側でも FrameCard クリック → AddMeal フォームに `frame_entry_id` を渡す → 既存フローを使いまわせる。

---

## 議題2: Command 層のオーケストレーションをどこに置くか

### 前提（現状の構造）

- GraphQL resolver（`AddMealWithNewDish` 等）が複数 Command を直接呼んでオーケストレーションしている
- Command 層には `AddMealCommand`（Meal 単体）のみ存在
- 「Commandはオーケストレーションのみ担い、ビジネスロジックをCommand内に書かない」というアーキテクチャ方針がある

### 論点

`frame_entry_id` が渡された場合、Meal 作成後に `MealFrameEntry.fill_with_meal` を呼ぶ必要がある。この処理をどこに置くか。

**選択肢1: オーケストレーションは resolver に残す（現状踏襲）**
- resolver が `AddMealCommand` → MealFrameEntry 更新 と順に呼ぶ
- 業務ロジックがプレゼンテーション層（resolver）に漏れ続ける

**選択肢2: gateway Command を作りオーケストレーションを移す**
- resolver は gateway を呼ぶだけ（薄くなる）
- gateway 内で `AddMealCommand` 等を呼ぶ
- 既存 resolver のリファクタも発生する

### 決定理由（選択肢2 を採用）

MealFrame は「付属品」ではなく「立派なビジネスオブジェクト」として今後も成長していく。「枠に料理を当てはめて食事として確定する」という操作は、ドメイン上意味を持つユースケースであり、resolver（プレゼンテーション層）がオーケストレーションするのは責務の越境になる。

今のうちに層の責務を正す方が長期的なコストが低い。

### 結論

**Command 層に gateway Command を作り、resolver からはその窓口を呼ばせる。gateway 内で `AddMealCommand` 等の既存 Command を呼ぶ構成を採用する。**

---

## 議題3: gateway Command は必要か・`FillFrameEntryWithMealCommand` は誰が呼ぶか

### 論点

gateway Command（`RegisterMealCommand`）を作るとした場合、その内部で `AddDishCommand` も呼ぶことになる。しかし Dish と Meal は別ドメインであり、現状も resolver が両者を別々に呼んでいる。gateway が Dish 作成を内包するのはドメイン境界を壊す設計になる。

また `Add` と `Register` が同じレイヤで同じことを指す命名になり、表記揺れが発生する。

### 結論

**gateway Command は作らない。`AddMealCommand` に `frame_entry_id`(optional) を追加し、ある場合は Meal 作成後に `MealFrameEntry#fill_with_meal` を呼ぶ形を採用する。**

- `FillFrameEntryWithMealCommand` は不要
- `addMealFromFrameEntry` という独立 GraphQL Mutation も不要
- Dish 作成は引き続き resolver 側が担う（現状踏襲）
- `AddMealCommand` の責務拡張は薄い（frame_entry_id がある場合の fill のみ）ため許容範囲
