# FR-034: 旧FrameEntryと現行Frame::Entryの実装が併存する

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 要調査
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-016（現行コードで再確認）。

## 対象

- [backend/app/domain/business/food/meal/frame_entry/usecase/fill_with_meal_command.rb](../../../../../backend/app/domain/business/food/meal/frame_entry/usecase/fill_with_meal_command.rb)
- [backend/app/domain/business/food/meal/frame/entry/usecase/fill_with_meal_command.rb](../../../../../backend/app/domain/business/food/meal/frame/entry/usecase/fill_with_meal_command.rb)
- [backend/app/models/meal_frame_entry.rb](../../../../../backend/app/models/meal_frame_entry.rb)

## 問題と根拠

旧namespaceにrootと登録/割当/削除Commandが残り、現行とほぼ同じ永続化処理を持つ。モデルが返すrootは現行namespaceなのに、旧Commandからも同じモデルを呼ぶ。所有者確認等を片側だけに追加すると将来旧経路から迂回し得る。現時点のGraphQL呼出しは現行側だが、動的参照・外部スクリプトの不存在までは確認できていない。

## 改善案

定数名・autoload・テスト・運用scriptの参照を確認してから旧実装を削除する。互換利用がある場合は二重実装を維持せず、現行へ委譲する期間を決める。

## 振る舞いを維持する条件

未確認の呼び出しがある可能性を除外してから判断する。現段階では削除を自動適用しない。

## 検証方法と確認結果

静的参照検索に加えeager loadと全体specを実行する。削除判断前に外部利用を確認する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
