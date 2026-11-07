# 原子的辞書反映specの移管台帳（baseline 94623f6）

| 旧操作 | 直接describe / 辞書fixture | 共通期待 |
| --- | --- | --- |
| add | AddCommand / 辞書なし | 後半失敗・先行料理/タグ実保存・全属性rollback |
| update | UpdateCommand / 既存辞書 | 同上 |
| remove | RemoveCommand / 既存辞書 | 同上 |
| reflect | ReflectLatestNormalizeWordCommand / 既存辞書 | 同上 |

各操作の例外type/message、観測1回、先行料理とタグが旧値から変更、辞書全行・2料理・各タグ全attributesのrollbackをshared examplesへ移す。辞書と共通fixtureの生成後にsnapshotし、operation分岐と位置依存を除く。productionは変更しない。

2026-11-07 attempt 2: 4具体Command・直接subjectとnamed let snapshot、名前付き観測/aggregateへ移管。関連4 examples、全RSpec 862 examples、全RuboCop 474 files / 0 offenses。[結果](atomic-spec-attempt-2/result.md)。attempt 1の規約不適合と実測は保持。
