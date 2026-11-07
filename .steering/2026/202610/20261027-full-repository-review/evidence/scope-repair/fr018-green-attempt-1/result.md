# FR-018 transaction green検証

request: `scope-repair-fr018-green-1`、attempt: 1、status: failed。

- 指定RSpec: 30 examples、0 failures。新旧Commandの実保存後のrollbackと元例外、正常交換・返却・所有者scopeの関連例が成功した。
- 指定RuboCop: 4 files inspected、2 offenses、終了コード1。両specの`raise_error` blockに`Lint/AmbiguousBlockAssociation`が各1件ある（food spec:345、dish spec:121）。直接原因はmatcher引数の括弧不足で、matcherを括弧で明示して再検証することを推奨する。
- production差分は2 Commandの`Meal.transaction` wrapperのみ。取得・保存・concatの順序と引数を保持し、他のproduction fileに未commit差分はない。
- 保護3 fileのSHA-256は保存hashと一致。Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。`git diff --check`成功。

RSpecは成功したがlint未達のためrequest全体はfailed。red結果は変更していない。
