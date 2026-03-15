# BulkTagDrawer

複数の料理に一括でタグを追加するドロワーコンポーネント。

## vaul の modal={false} について

`<Drawer modal={false}>` を設定している。

### 理由

タッチデバイス（iOS Safari / Chrome DevTools touch emulation）で「タグを付ける」ボタンをタップすると、
ドロワーが開いた直後に自動的に閉じてしまう問題があった。

**原因**: vaul の `DrawerContent` は `onFocusOutside` を `modal=true`（デフォルト）のとき
何もせずに素通りさせる。ドロワーが mount される瞬間、focus がボタン（ドロワー外）に残っているため、
Radix の DismissableLayer が「focus が外に出た」と判定してドロワーを close する。

**修正**: `modal={false}` にすると vaul の `onFocusOutside` / `onPointerDownOutside` が
`e.preventDefault()` を呼ぶようになり、外部イベントでドロワーが閉じなくなる。

### 既知の問題

**Chrome DevTools 縦向きタッチエミュレーターでドロワーが開かない**

`modal={false}` を含む複数の修正を試みたが、Chrome DevTools の縦向き（portrait）タッチエミュレーターでは
ドロワーが依然として開かない。横向き（landscape）エミュレーター・実機では正常動作することを確認済み。

Chrome DevTools のタッチエミュレーションが実機の挙動を完全には再現しないことによるもので、
実用上の問題はないと判断して対応を保留している。

### 副作用

- `modal={false}` によりフォーカストラップが無効になる（ドロワー外の要素にフォーカスが当たることがある）
- オーバーレイをタップしてもドロワーが閉じない
- ドロワーを閉じるには「キャンセル」ボタンを使う（またはタグ追加完了時に自動クローズ）
