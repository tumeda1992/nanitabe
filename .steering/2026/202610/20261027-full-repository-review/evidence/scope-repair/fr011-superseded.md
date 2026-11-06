# FR-011 旧取消検証の位置づけ

`requests/scope-repair-fr011-1.json` と `evidence/scope-repair/fr011-attempt-1/result.json` / `result.md` は旧取消目的に対する実測履歴として保持する。その目的は現在の正常操作を保つ内部改善復帰方針により superseded となった。旧 result の passed は取消時の事実であり、現在の料理 owner 認可の検証結果ではない。3 path は現在 HEAD と一致し、cdb8e27 の認可実装を保持する。新しい検証は `requests/scope-repair-fr011-retain-1.json` に記録する。
