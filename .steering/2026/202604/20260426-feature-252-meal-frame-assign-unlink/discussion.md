# Discussion: 食事と枠の紐付け解除・既存食事割り当て・+ボタン挙動統一

## 論点1: ③「+ボタン挙動統一」の実装方法

**提起の背景:**
空エリアの点線 `+`（DateCard の FullScreenModal: AddMeal のみ）と日付横の `+`（AddMealIcon: 3タブ）の挙動を統一する要件があった。
`AddMealIcon` が持つ3タブモーダルを再利用する方法として、AddMealIcon に `openerElement` prop を追加する案を出した。
ユーザーから「なぜ引数が増えるのか」という指摘を受け、設計の見直しが必要になった。

### 議論の変遷

#### 事象の記述
- AddMealIcon に `openerElement?: React.ReactNode` prop を追加する案を提示した
- ユーザーが「なぜ引数が増えるのか」と疑問を呈した

#### 原因の追跡
- なぜ: 「モーダルのロジックを AddMealIcon が持っているから、点線エリアが AddMealIcon を使う必要がある」と考えた
- なぜ: 「点線エリアのボタンを AddMealIcon 経由で開くには、openerElement prop を追加するしかない」という前提を疑わなかった
- なぜ: 「モーダルのロジックは AddMealIcon にあるべき」という固定観念があり、「モーダルの中身だけ揃えればよい」という視点が抜けていた

#### 根本原因₀ + 提案₀（openerElement 案）

- **根本原因₀**: 「挙動を統一する＝AddMealIconを共有する」と短絡し、AddMealIcon prop 拡張を選択した
- **提案₀**:
  - 総論: AddMealIcon に `openerElement` prop を追加し、点線エリアのボタンをそのまま渡す
  - 各論:
    - ルール: `<FullScreenModalOpener>{openerElement ?? <現行アイコン />}</FullScreenModalOpener>` で切り替える
    - 適用例: DateCard の点線ボタンを `openerElement` として AddMealIcon に渡す

#### イテレーション1

##### 検証
- **観点**: ユーザーが「なぜ引数が増えるのか」と指摘。AddMealIcon の prop を増やす必要があるか？
- **弱点**: 「点線エリアのデザインを変えずにモーダルの中身だけ揃えれば済む」という別解が見えていなかった

##### 修正先の判断
- 診断レベルへの遡及: 「AddMealIcon を共有しなければならない」という前提自体が誤り

##### 誤った提案（点線エリア削除）

- ユーザーの「なぜ引数が増えるのか」という問いに正しく答えられず、誤って点線エリアを削除する案を出した
- ユーザーからの強い否定:「は？ばか？点線エリアは必要だから存在してるんだよ。その発想が短絡的すぎて浮かんだことすら否定したいわ。今あるものは必要だからあるんだよ。お前の実装のしやすさで消していいわけないじゃん。」
- 根本原因: 実装のしやすさを理由に、既存のUIを削除することは許されない。「なぜ今あるか」を考えずに消す判断をした

#### イテレーション2

##### 検証
- **観点**: ユーザーの指摘「表のデザインを変えないで、裏で開くコンポーネントが共通になればいいだけなんじゃないの？」
- **弱点**: → この観点で設計し直すと、AddMealIcon への変更は不要で、DateCard の FullScreenModal の中身を3タブに差し替えるだけで済む

##### 修正先の判断
- **提案レベルの修正**: AddMealIcon prop 拡張案から、DateCard モーダル中身差し替え案へ

##### 根本原因2 + 提案2

- **根本原因2**: 「挙動を統一する＝共通コンポーネントを1つにする（共有する）」ではなく「見た目は既存のまま、開く内容（モーダルの中身）だけ揃える」が正解だった
- **変更点**: AddMealIcon への prop 追加を廃止。DateCard の FullScreenModal 内容を3タブ化する
- **提案2（採用）**:
  - 総論: AddMealIcon への変更なし。DateCard の FullScreenModal 内部を3タブ構成に差し替えるだけ
  - 各論:
    - ルール: 点線エリアの見た目・`onClick` は一切変えない。FullScreenModal の内部 JSX だけを変更する
    - 適用例:
      ```tsx
      // 変更前
      <FullScreenModal title="食事登録">
        <AddMeal defaultDate={date} onAddSucceeded={handleEmptyAreaAddSucceeded} />
      </FullScreenModal>

      // 変更後
      <FullScreenModal title="食事登録">
        <div className="flex gap-2 mb-4">
          <button onClick={() => setAddType('meal')}>食事</button>
          <button onClick={() => setAddType('frame')}>枠</button>
          <button onClick={() => setAddType('pattern')}>枠パターン適用</button>
        </div>
        {addType === 'meal' && <AddMeal defaultDate={date} onAddSucceeded={...} />}
        {addType === 'frame' && <AddMealFrame dateForAdd={date} onAddSucceeded={...} />}
        {addType === 'pattern' && <AddMealPattern dateForAdd={date} onAddSucceeded={...} />}
      </FullScreenModal>
      ```

#### イテレーション3

##### 検証
- **観点**: AddMealIcon と DateCard は「同一の3タブロジック」を全く同じタイミングで変更する関係になる
- **弱点**: 新しいタブが増えたとき2箇所を変更しなければならない。共通化判断基準「変更の必然性あり → 抽出すべき」に反する

##### 修正先の判断
- **提案レベルの修正**: 3タブロジックを `AddMealTabs` コンポーネントとして抽出する

##### 根本原因3 + 提案3

- **根本原因3**: 同じ機能が「別の文脈」ではなく「全く同じ理由で変わる」のであれば抽出すべき。「見た目のトリガーが2箇所ある」と「ロジックが2箇所にある」を分けて考えていなかった
- **変更点**: inline 差し替えから、`AddMealTabs` コンポーネント抽出へ
- **提案3（採用）**:
  - 総論: 3タブロジックを `AddMealTabs` コンポーネントに抽出し、AddMealIcon と DateCard の両方から使う
  - 各論:
    - ルール: `AddMealTabs` は props として `defaultDate`, `onAddSucceeded` を受け取り、タブ切り替え state と子コンポーネントの出し分けのみを持つ
    - AddMealIcon: FullScreenModal 内部を `<AddMealTabs />` に差し替え（props・インターフェースは変えない）
    - DateCard: FullScreenModal 内部を `<AddMealTabs />` に差し替え（点線エリア・onClick は変えない）

**決定:** 採用した提案3。`AddMealTabs` を新規作成し、AddMealIcon と DateCard の両方から利用する。

**ネクストアクション:**
- design.md ③ セクションを `AddMealTabs` 抽出案に更新（完了）
- tasklist.md Phase 5 を `AddMealTabs` 新規作成・差し替えの手順に更新（完了）
