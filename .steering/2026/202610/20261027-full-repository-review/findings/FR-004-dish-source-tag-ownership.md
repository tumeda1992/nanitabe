# FR-004: 料理・出典・一括タグの更新が所有者を検証しない

- 優先度: P1
- 採否: 採用
- 対応状況: 完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-006（現行コードで再確認）。

## 対象

- [backend/app/domain/business/food/dish/usecase/update_command.rb](../../../../../backend/app/domain/business/food/dish/usecase/update_command.rb)
- [backend/app/domain/business/food/dish/source/usecase/update_command.rb](../../../../../backend/app/domain/business/food/dish/source/usecase/update_command.rb)
- [backend/app/domain/business/food/dish/tag/usecase/add_tag_to_dish_command.rb](../../../../../backend/app/domain/business/food/dish/tag/usecase/add_tag_to_dish_command.rb)

## 問題と根拠

いずれも既存rootをIDのみで取得する。user_idを受け取っていても対象rootのuser_idと照合しない。別ユーザーの料理名・出典を改変でき、一括タグでは他人の料理へ操作ユーザーのタグを作れる。削除Commandの所有者条件が正しくても更新は保護されない。

## 改善案

更新対象の認可をroot取得時に統一する。一括タグは全IDの所有者を確認し、一件でも不正なら全体をロールバックする。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

料理・出典更新と、本人/他人IDを混ぜた一括タグを検証し、関連データまで不変であることを確認する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 2026-11-01の反映指示により採用
- 適用コミット: `8adcbd6`

## 適用結果（2026-11-01）

料理更新・出典更新・単一タグ追加のCommandでrootの所有者を確認し、他人のIDを不存在と同じエラーで拒否する。一括タグは既存transactionにより、本人の料理へのタグ追加後に他人の料理を検出した場合も全件rollbackする。

新規`spec/domain/business/food/dish/ownership_spec.rb`で3 examples / 3 failuresを確認後、修正して関連41 examples / 0 failures。料理更新・出典更新・タグ各Command、および通常料理更新・新規出典付き料理更新・出典更新・一括タグ追加のGraphQL specを含む。変更4ファイルのRuboCopは違反なし。実行は既存の開発用`docker compose -f compose.dev.local.yml exec -T backend`内。既存タグcontentの保存挙動はCR-002で扱い、この指摘では変更していない。
