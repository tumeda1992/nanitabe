# 要件ドキュメント

## はじめに
料理検索ページ (`/dishes`) で複数の料理を選択し、同じタグを一括付与できるようにする。
バックエンドの `bulkAddTagToDishes` mutation を呼ぶフロントエンド実装を追加する。

## 元の依頼内容
料理検索のfronetendページで、選んだ複数の料理に対して、同じタグを設定できるようにしたい。
使うgraphql mutation はbulkAddTagToDishes

複数料理選んだときにできることは、今削除だけかもしれないけど、
デザインはここにあったかな、どうだったろう
.steering/2026/20260307-feature-201-apply-v0-calendar-design/nanitabe_v0_design

## 要件

### 要件1: 選択済み料理への一括タグ付け
**ユーザーストーリー:** 料理検索ページで複数の料理を選択し、同じタグをまとめて付けたい。

#### 受け入れ基準
1. WHEN 1件以上の料理を選択している THEN フローティングバーに「タグを付ける」ボタンが表示される
2. WHEN 「タグを付ける」を押す THEN タグ入力ドロワーが開く
3. WHEN タグ名を入力して「追加」を押す THEN `bulkAddTagToDishes` が呼ばれ、選択した全料理にタグが付く
4. WHEN 追加が成功した THEN ドロワーが閉じる
5. WHEN タグ名が空 THEN ボタンが無効化される

---

# 設計ドキュメント

## TL;DR
既存のフローティングバーに「タグを付ける」ボタンを追加し、押すと `BulkTagDrawer` が開く。
ドロワーはタグ名入力フォーム + 追加ボタンのシンプルな構成。
`bulkAddTagToDishes` mutation用のフック (`useBulkAddTagToDishes`) を新設して呼び出す。

## v0 デザインとの差分

v0 の `BulkTagDrawer` は以下を持つが、現バックエンドAPIとの乖離がある：
- 既存タグをカラー付きチップで一覧表示・選択 → バックエンドはタグIDでなく文字列で受け取る。カラーも未サポート
- 複数タグを一括付与 → `bulkAddTagToDishes` は1タグずつ（1回のmutationで1タグ）

**今回の実装方針（スコープを絞る）:**
- タグ名テキスト入力1フィールド + 「追加」ボタン
- 1回のmutationで1タグのみ付与
- 既存タグ一覧表示・カラー選択は対象外（将来対応）

v0 と完全に一致させるより、バックエンドAPIの実態に合わせシンプルに実装する。

## 変更点サマリ

| ファイル | 追加/変更 |
|---------|---------|
| `frontend/src/features/dish/tag/bulkAddTagMutation.ts` | **新規** GraphQL mutation + hook |
| `frontend/src/components/dish/BulkTagDrawer/index.tsx` | **新規** タグ入力ドロワーコンポーネント |
| `frontend/src/app/dishes/page.client.tsx` | **変更** フローティングバーに「タグを付ける」ボタンと BulkTagDrawer を追加 |
| `frontend/src/lib/graphql/generated/graphql.ts` | **再生成** bulkAddTagToDishes mutation を含める |

## 設計詳細

### GraphQL codegen

バックエンドに `bulkAddTagToDishes` を追加済みのため、フロント側でも codegen を実行して型・hookを生成する：
```
docker compose exec frontend yarn codegen
```

### mutation hook: useBulkAddTagToDishes

`removeDishMutation.ts` と同パターンで実装：

```ts
export const BULK_ADD_TAG_TO_DISHES = gql`
  mutation bulkAddTagToDishes($dishIds: [Int!]!, $tag: String!) {
    bulkAddTagToDishes(input: { dishIds: $dishIds, tag: $tag }) {
      dishIds
    }
  }
`;

export const useBulkAddTagToDishes = () => {
  const [bulkAddTagToDishes, loading, error] =
    buildMutationExecutor<{ dishIds: number[]; tag: string }, BulkAddTagToDishMutation>(
      useBulkAddTagToDishMutation,
    );
  return { bulkAddTagToDishes, bulkAddTagToDishesLoading: loading, bulkAddTagToDishesError: error };
};
```

### BulkTagDrawer コンポーネント

```tsx
type BulkTagDrawerProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  dishIds: Set<number>;
  onCompleted?: () => void;
};
```

内部実装：
- `tagName` state（テキスト入力）
- open変更時に入力をリセット
- 「追加」ボタン押下で `bulkAddTagToDishes({ dishIds: [...dishIds], tag: tagName })` → 成功で close

### page.client.tsx の変更

フローティングバーのアクションボタン群に追加：

```tsx
<Button variant="outline" size="sm" className="gap-1.5 text-xs flex-1"
  onClick={() => setBulkTagOpen(true)}>
  <Tag className="size-3.5" />
  タグを付ける
</Button>
```

`<BulkTagDrawer open={bulkTagOpen} onOpenChange={setBulkTagOpen} dishIds={selectedIds} />`

## 代替案

### 代替案1: v0デザイン通り既存タグ一覧表示
- 既存タグをドロワーでチップ表示・選択可能にする
- バックエンドAPIは文字列なのでチップのcontentをそのまま渡せるが、全料理のタグを集めるクエリが必要
- 棄却理由: スコープが広がる。まずシンプルな入力UIから始める

### 代替案2: 複数タグを一度に入力
- カンマ区切りなどで複数タグを一度に付与
- 棄却理由: バックエンドは1タグずつのAPI。複数対応は別途API拡張が必要

## リスクと対策
- **codegen失敗**: バックエンドコンテナが起動していないと失敗 → `docker compose ps` で確認
- **DrawerのzIndex問題**: 過去にvaul Drawerが FullScreenModal の裏に出た事例あり → 今回は dishes ページ単体なのでモーダル競合なし

## テスト方針
- コンテナ内実行: `docker compose exec frontend yarn test`
- テストファースト
- `BulkTagDrawer` コンポーネントのテスト
  - タグ名が空のとき追加ボタンが無効
  - タグ名入力後に追加ボタンを押すと mutation が呼ばれる
  - mutation成功でドロワーが閉じる
- mutation hookは生成コードへの薄いラッパーのためテスト対象外
