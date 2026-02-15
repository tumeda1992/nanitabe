# 要件ドキュメント

## はじめに

この機能は、既存の `Business::Food::Dish::Word::Usecase::AddCommand` の機能を公開するGraphQL mutationエンドポイントを追加します。このコマンドにより、ユーザーは料理名の単語正規化ルールを追加でき、料理名のバリエーションを標準化できます（例：「トマト」と「tomato」を同じ正規形式にマッピング）。

## 用語集

- **NormalizeWord**: 単語正規化マッピングを保存するデータベースエンティティ
- **Source**: 正規化される元の単語/フレーズ
- **Destination**: sourceがマッピングされる正規形式（オプション、デフォルトは正規化されたsource）
- **GraphQL_Mutation**: サーバー側のデータを変更するGraphQL操作
- **Command**: ビジネス操作を実行するユースケースクラス

## 要件

### 要件1: 単語正規化Mutationの追加

**ユーザーストーリー:** 認証済みユーザーとして、GraphQL経由で単語正規化ルールを追加したい。そうすることで、システム内の料理名のバリエーションを標準化できる。

#### 受け入れ基準

1. WHEN 認証済みユーザーがsource単語を提供する THEN GraphQL_Mutation SHALL 正規化されたsourceをsourceとdestinationの両方として持つ正規化ルールを作成する
2. WHEN 認証済みユーザーがsourceとdestination単語の両方を提供する THEN GraphQL_Mutation SHALL 正規化されたsourceを正規化されたdestinationにマッピングする正規化ルールを作成する
3. WHEN ユーザーがsource単語なしで正規化ルールを追加しようとする THEN GraphQL_Mutation SHALL バリデーションエラーを返す
4. WHEN 正規化ルールが正常に作成される THEN GraphQL_Mutation SHALL 既存の料理に対して最新の正規化単語の反映をトリガーする
5. WHEN 正規化ルールが正常に作成される THEN GraphQL_Mutation SHALL 成功インジケーターを返す

### 要件2: 認証と認可

**ユーザーストーリー:** システム管理者として、認証済みユーザーのみが正規化ルールを追加できるようにしたい。そうすることで、データの整合性が維持される。

#### 受け入れ基準

1. WHEN 未認証ユーザーがmutationを呼び出そうとする THEN GraphQL_Mutation SHALL 認証エラーを返す
2. WHEN 認証済みユーザーがmutationを呼び出す THEN GraphQL_Mutation SHALL リクエストを処理する

### 要件3: 入力バリデーション

**ユーザーストーリー:** 開発者として、明確なバリデーションエラーが欲しい。そうすることで、APIの利用者が何が間違っているかを理解できる。

#### 受け入れ基準

1. WHEN sourceパラメータが欠落または空である THEN GraphQL_Mutation SHALL sourceが必須であることを示すバリデーションエラーを返す
2. WHEN destinationパラメータが提供されているが空である THEN GraphQL_Mutation SHALL それを未提供として扱う
3. WHEN バリデーションが失敗する THEN GraphQL_Mutation SHALL データベースレコードを作成しない

### 要件4: トランザクションの安全性

**ユーザーストーリー:** システム管理者として、正規化ルールの作成がアトミックであることを望む。そうすることで、部分的な失敗がデータベースを破損しない。

#### 受け入れ基準

1. WHEN mutationが実行される THEN GraphQL_Mutation SHALL すべての操作をデータベーストランザクションでラップする
2. IF 実行中に任意の操作が失敗する THEN GraphQL_Mutation SHALL すべての変更をロールバックする
3. WHEN トランザクションが正常に完了する THEN GraphQL_Mutation SHALL すべての変更をアトミックにコミットする
