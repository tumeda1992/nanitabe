# FR-034: 旧FrameEntryと現行Frame::Entryの実装が併存する

- 優先度: P2
- 採否: 採用（全件適用の合意。旧定数は互換維持）
- 対応状況: 適用・関連/全体自動検証完了
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

## 適用結果（2026-11-02）

旧Root/Add/Removeを現行namespaceの継承・委譲へ変更し、FR-008で委譲済みのFillも含め永続化・認可の正本を現行に揃えた。旧Rootのclass名・6属性・validation・公開操作、Addの旧Root返却と保存一回を維持した。旧Removeの他人entry削除は、全件適用の認可契約に従い拒否する。

静的参照検索でGraphQL/モデル/既存spec/READMEを確認したが、外部scriptの不存在は断定しない。旧定数を残し、削除期限は設けない。利用確認ができ、削除を合意する際に改めて判断する。二層台帳と全contract照合は[evidence/fr034-migration.md](../evidence/fr034-migration.md)。

互換9件中1件の認可redを確認後、関連57 examplesとbackend全体885 examplesがすべて成功。変更4ファイルRuboCopとtest設定のzeitwerk:check成功。libがeager_load対象外という既存警告は残る。commitはapplication.mdとGit履歴で追跡する。
