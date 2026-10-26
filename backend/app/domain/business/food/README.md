# このモジュールについて
食事・料理に関するモジュール。

## ドメインオブジェクトのそれぞれの役割
（本来であれば、businessディレクトリ全体をこの作りにしたいが、まだ間に合っていないためこのディレクトリに限定）

- 集約ルート
  - 各モジュールのroot.rbが担当
  - モジュール外からのroot生成はfactory.rbが行う
- モジュール外への公開エンドポイント
  - ドメイン層の外（controllerなど）に公開するエンドポイント
    - usecaseディレクトリ配下のファイル
      - 処理クラスやいわゆるサービスクラスが配置されており、以下の分類
        - Command: データの変更を伴う処理
        - Finder: データの取得のみを行う処理
      - rootのメソッドなどビジネスロジックを呼び出すことにとどめて、このクラス内でビジネスロジックを実装することは基本的には避ける
        - ドメインロジックがビジネスロジックから散逸することを防ぐため
      - 異なる集約をまたぐオーケストレーションはプレゼンテーション層（controller・GraphQL resolver）が担う
        - Commandは自集約の内部だけを扱う。詳細な責務境界は[開発標準](../../../../docs/ai_guideline/development_standard/application_architecture.md#レイヤードアーキテクチャ)を正本とする
  - businessディレクトリ内の他モジュールへ公開するエンドポイント
    - usecaseディレクトリ配下のファイル
    - factory.rb
- 永続化
  - RailsのActiveRecordモデルが担当
    - 特別なRepositoryクラスは設けない（ActiveRecordが各DBMSの差分を吸収してくれるRepository層として優秀であるため）

## サブモジュール一覧

| サブモジュール | 役割 |
|---|---|
| `Dish` | 料理マスタ |
| `Meal` | 食事記録（日付 + 料理が確定した記録。`dish_id` は常に必須）。サブモジュールとして `Frame`（枠マスタ、その配下に `Frame::Entry` と `Frame::Pattern`）・`Postponed`（延期された食事）を持つ |

枠エントリの現行namespaceは `Meal::Frame::Entry`。旧 `Meal::FrameEntry` の実装も残っているため、移行・削除時には動的参照を含めた利用確認が必要である。現行構成と変更ガイドは[meal/README.md](./meal/README.md)を参照する。

### Meal・MealFrameEntry・PostponedMeal の違い

`Meal` は日付・時間帯・料理の3つすべてが決まった状態である。残り2つのモデルは、それぞれ異なる軸を未決のまま表現する。

| | 決まっているもの | 未決 |
| --- | --- | --- |
| `Meal` | 日付 + 時間帯 + 料理 | なし |
| `MealFrameEntry` | 日付 + 時間帯 + 枠 | 料理 |
| `PostponedMeal` | 料理 + 時間帯 | 日付 |

- `Meal` = 日付 + 時間帯 + 料理が決まった記録（`dish_id` は常に必須）
- `MealFrameEntry` = 日付 + 時間帯 + 枠が決まった計画（料理未決定の状態を扱う）
- `PostponedMeal` = 料理 + 時間帯が決まった意思（日付未決定の状態を扱う）
- これらは別エンティティとして設計されており、`meals.dish_id` を nullable にすることは禁止
