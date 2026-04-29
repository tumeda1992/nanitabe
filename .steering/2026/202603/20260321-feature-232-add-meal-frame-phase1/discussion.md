# Discussion: フェーズ1 MealFrame として成立する

---

## 論点1: MealFrameEntry が残っている MealFrame の削除挙動

**提起の背景:** design.md 作成時に要議論として立てた。MealFrame（マスタ）削除時に紐づく MealFrameEntry をどう扱うか設計上の選択が必要だった。

**議論の変遷:**
- Claude が設計オプションを A（CASCADE）/ B（ブロック）として提示
- フェーズ2 で Meal → MealFrameEntry の関係が追加される点を踏まえ、CASCADE は影響範囲が広すぎると判断
- ユーザーが B（ブロック）を即決

**決定:** B（ブロック）— MealFrameEntry が存在する場合は MealFrame の削除を禁止

**決定理由:** CASCADE だと「枠を消したら知らないうちにカレンダーのエントリが消えた」という UX リスクがある。ユーザーが先にエントリを削除してからマスタを削除する手順を踏ませる方が明示的で安全。

---

## 論点2: MealFrameEntry に `meal_type`（朝/昼/夕）を持たせるか

**提起の背景:** design.md 作成時に要議論として立てた。枠がカレンダー上のどの食事区分に属するかを表現する必要があるかどうかの問い。

**議論の変遷:**
- ユーザーから「昼夜どっちも枠を決めたときにどっちかわからなくなっちゃうな」という懸念が出た
- Claude も同意。カレンダーは `meal_type` で並び順が制御されており、枠だけ meal_type なしで浮くと表示上の曖昧さが生じる

**決定:** A（持たせる）

**決定理由:** 「月曜夜はパスタ枠」のような計画を表現するために meal_type は必要。枠もカレンダーの朝・昼・夕いずれかに属した方が表示・並び順が整合する。

---

## 論点3: MealFrameEntry に `meal_id` はあるか / Meal との関係方向

**提起の背景:** ユーザーから「MealFrameEntry に meal_id ないの？」「meal_frame_entry は中間テーブル的な認識だと思っていた」という問いが出た。

**議論の変遷:**
- [前提] Claude の初期設計（design.md 時点）では `meals.meal_frame_entry_id`（nullable）を追加する方向（Meal → MealFrameEntry）で設計していた。ロードマップの「AddMealCommand に frame_entry_id を追加」という記述を根拠に A 方向を推奨していた
- [疑問/反論] ユーザー: 「MealFrameEntry に meal_id ないの？meal_frame_entry は中間テーブル的な認識だと思っていた」
- [応答] Claude: ロードマップの記述を根拠に Meal 側が FK を持つ A 方向を推奨
- [疑問/反論] ユーザー: 「meals はコアテーブル（user_id/date/meal_type/dish_id すべて必須）であり、nullable なカラムを追加しまくるのはモデリングの敗北」
- [変化点] Claude が認識を改めた: Meal は MealFrameEntry なしで独立して存在できる。関連付けの責務は、関連付けのために存在する MealFrameEntry が担うのが自然。`meal_frame_entries` が中間テーブルとして両者をつなぐのが正しいモデル
- ロードマップ・feature-64/design.md・feature-64/discussion.md も同様に修正済み（横展開漏れの目印として feature-64/discussion.md に変更経緯を追記）
- [補足] ユーザーより認識の精緻化: 「nullable な値で埋めない」は表面的な理由。本質は「Meal は MealFrameEntry なしでも存在できる」「関連付けは関連付けのために存在する MealFrameEntry に役割を任せる」というモデルの責務設計にある

**決定:** `meal_frame_entries.meal_id`（nullable）を持つ。`meals` テーブルは変更しない。

**決定理由:** Meal は MealFrameEntry なしで独立して存在できる。関連付けの責務は、関連付けのために存在する MealFrameEntry が担うのが自然であり、MealFrameEntry に meal_id を持たせることはその責務設計の帰結である。meals テーブルを変更しないこと・コアテーブルを汚さないことは結果として得られる副次的メリット。フェーズ2 の操作は「Meal 作成 → resolver が MealFrameEntry::FillWithMealCommand を呼んで meal_id をセット」というオーケストレーション構造になる（アーキテクチャ方針「異なる集約をまたぐオーケストレーションはプレゼンテーション層が担う」に合致）。

---

## 論点4: MealFrameEntry はどのドメインに帰属するか

**提起の背景:** Claude が design.md で `Business::Food::MealFrameEntry` として Dish・Meal と並列に配置していた。ユーザーから「MealFrame は dish, meal と並列の存在？MealFrameEntry は独立させているけどデータの保存上別テーブルになるだけで集約を作るべき存在？」という問いが出た。

**議論の変遷:**
- [前提] Claude の設計: `Business::Food::MealFrameEntry` として Dish・Meal と同列の独立集約として配置していた
- [疑問/反論] ユーザー: 「meal_entry は meal の中の概念でしょ」
- [変化点] MealFrameEntry は Meal ドメインの内部概念であり、`Business::Food::Meal::FrameEntry` に帰属すべき。Dish・Meal と並列に置くのは誤り

**決定:** `Business::Food::Meal::FrameEntry` として Meal ドメイン内に配置する

**決定理由:** MealFrameEntry は「カレンダーのある日時に枠を置く」という Meal ドメインの文脈で意味を持つ概念。Dish・Meal と並ぶ独立したドメイン概念ではない。

**追記1:** モジュールのトップレベルや `Business::Food` レイヤへの追加は重い判断。ホイホイ新しいトップレベル集約を追加しない。既存のドメイン概念に帰属できないか先に考えること。

**追記2:** 当初 `Business::Food::MealFrame::Root` として Food 直下に置いていたが、これも誤り。MealFrame は Meal の補助的概念であり、「MealFrame と Meal は別のもの？」と聞かれたら「近い概念」と答える関係——こういう近しい概念のまとまりをコードのモジュールで表現する。暗黙の管理にしない。結論: `Business::Food::Meal::Frame::Root` として FrameEntry と同じ Meal モジュール下に揃えた。

---

## 論点5: Meal::FrameEntry を集約として設計すべきか

**提起の背景:** ユーザーから「データの保存上別テーブルになるだけで、集約を作るべき存在か？」という問いが出た。中間テーブルの操作はデータ上の関連付けの追加・削除にすぎないのでは、という認識から。

**議論の変遷:**
- [前提] ユーザーの認識: MealFrameEntry は中間テーブルなので、ビジネスロジックは Meal にメソッドとして生えるのでは
- [疑問/反論] Claude: フェーズ1 では Meal がまだ存在しない（meal_id=null）。`meal.add_frame_entry(...)` を呼ぶべき Meal がいない
- [応答] ユーザー: 「でも meal が空のときがあるのか」と自ら気づく
- [応答] Claude が選択肢を整理:
  - A: MealFrame にメソッド `place_on_calendar(date:, meal_type:)` → 成立するが MealFrame がカレンダー配置まで知ることになり責務過多
  - B: 独立集約 `Meal::FrameEntry::Root` + Usecase → 既存パターン踏襲だが思考停止の集約化リスク
  - C: Command でアドホックに対応 → ドメイン知識が Command に漏れる
  - D: Policy + 薄い Entity で表現 → 既存の `AttachDishPolicy` パターンに近い形
- [疑問/反論] ユーザー: 「D について、データ保存前のビジネスロジックをどう表現するんだろう」
- [変化点] Command 内で保存前の状態を持つオブジェクトが必要になった瞬間、それは `Meal::FrameEntry::Root` になる。D は B に収束する。「思考停止で集約化」への懸念は「集約を作るかどうか」ではなく「どれだけ厚くするか」の問いに変換される

- [補足] ユーザーより: MealFrameEntry の集約化はテーブル構造に引きずられた安易な集約化ではないかと危惧して再考を迫った。ビジネスロジックとテーブル構造は独立した存在であり、「別テーブルがある → 集約を作る」という短絡をしてはならない。今回 B に至ったのはその問いを経た上での結論

**決定:** B（`Meal::FrameEntry::Root` として集約を作る。ただし既存の薄い Root パターンに従い過剰に厚くしない）

**決定理由:** 保存前のビジネス状態を持つオブジェクトが必要である以上、集約 Root を作ることは避けられない。既存の `Meal::Root`（薄い validations + Usecase が orchestrate）パターンを踏襲すれば過剰設計にならない。「テーブルがあるから集約を作る」ではなく「保存前の状態を表現するドメインオブジェクトが必要だから集約になる」という順序が正しい。

---

## 論点6: FullScreenModal（`+` ボタン）のデフォルト

**提起の背景:** ユーザーから「最初に食事か枠かを選ばなくちゃいけない？それとも特段枠が選ばれなければ食事がデフォルト？」という問いが出た。

**議論の変遷:**
- [前提] Claude の提案: `+` を押したら食事フォームがデフォルト表示。モーダル内上部にタイプセレクタ（タブ/ラジオ）を置き、「枠」に切り替えた場合のみ枠フォームに変わる
- [応答] ユーザー: 認識と同じだった。毎回食事と枠のどちらかを選ばないと食事を登録できないのは億劫。`+` を押したら食事登録が開いて、枠を登録したいときだけ選択を変えるイメージだった

**決定:** `+` ボタンを押すと食事登録フォームがデフォルト表示。枠を登録したい場合のみタイプセレクタで切り替える

**決定理由:** 普段の操作（食事追加）のクリック数を増やさない。既存 AddMeal コードを壊さない。`useChoosingDishType` と同じ切り替えパターンで実装できる。

---

## 論点7: MealFrame CRUD バックエンドのフェーズ粒度

**提起の背景:** tasklist.md 初版でフェーズ1に「ARモデル + Root + 4つのCommand/Finder + 4つのGraphQL mutation/query + 全spec」を詰め込んだ。ユーザーから「フェーズ1でかくね？」と指摘が入った。

**議論の変遷:**
- [前提] Claude の初版: MealFrame CRUD を1フェーズにまとめていた
- [疑問/反論] ユーザー: フェーズが大きすぎる
- [応答] Claude: CRUD を1操作1フェーズに分割する案を提示（一覧取得・新規作成・編集・削除）

**決定:** CRUD を1操作1フェーズに分割する
- フェーズ1: 一覧取得（ARモデル + Root + IndexFinder + mealFrames query）
- フェーズ2: 新規作成（AddCommand + addMealFrame mutation）
- フェーズ3: 編集（UpdateCommand + updateMealFrame mutation）
- フェーズ4: 削除（RemoveCommand + deleteMealFrame mutation）

**決定理由:** 各フェーズが「独立して完結・検証できる変更単位」になる。tasklist-executor が1フェーズを実行・確認してから次へ進めるため、失敗時の原因特定も容易になる。
