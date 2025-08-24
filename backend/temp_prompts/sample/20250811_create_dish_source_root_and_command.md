# タスク全体像
次のタスクを遂行してほしい

- [x] 食事のレシピ元のドメインモデル作成 
  - [x] 集約ルートの作成（テスト込）
  - [x] Factoryの作成（テスト込）
- [x] ユースケースコマンドの実装
  - [x] Add,Update用のparameterオブジェクトの作成（テスト込）
  - [x] AddCommandの実装（テスト込）
  - [x] UpdateCommandの実装（テスト込）
  - [x] RemoveCommandの実装（テスト込）

# 作業前提
- タスクの進め方の基本は @README.md を参照

# 背景
- DDD実現アーキテクチャを少し修正したいと思っている
  - アーキテクチャ変更なので、仕様は変わらない
  - すでに`app/domain/business/food/dish`ではアーキテクチャ反映済み

# 食事のレシピ元のドメインモデル作成
- アーキテクチャの参考元
  - `app/domain/business/food/dish/root.rb`など`app/domain/business/food/dish`配下
    - `docs/thinking_logs/testing/20250811.md`に記載の通りRepositoryを使わないでRepositoryにあたるところはActiveRecordを実行
- ビジネス仕様の参考元
  - `app/domain/business/dish/dish/source`
  - typeだけ`app/domain/business/food/dish/source/type.rb`としてValueObjectとして定義済み


# ユースケースコマンドの実装
`app/domain/business/food/dish/usecase`を参考に作ってほしい
