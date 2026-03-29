# Design: トランジティブ依存の脆弱性修正（Dependabot #191・#200・#237）

## 元の依頼内容

Coworkでブラウザ経由で脆弱性対応の調査してきた。これらを処理したい

---

## タスク
frontend/package.json に yarn resolutions を追加して以下 3 つの脆弱なパッケージを
固定バージョンに上書きし、yarn.lock を更新することで Dependabot アラート
#191・#200・#237 を解消する。

---

## 背景・調査結果

### 3 件の概要

| アラート | パッケージ | 脆弱バージョン | 修正バージョン | 脆弱性 | 深刻度 |
|---------|-----------|--------------|--------------|-------|-------|
| #237 | picomatch | 4.0.3 | 4.0.4 | ReDoS (CVE-2026-33671) | High 7.5 |
| #191 | minimatch | 9.0.5 | 9.0.7 | ReDoS | High 7.5 |
| #200 | immutable | 3.7.6 | 3.8.3 | Prototype Pollution | High 8.7 |

3 件とも `frontend/yarn.lock` 内のトランジティブ依存として存在しており、
`frontend/package.json` には直接記載されていない。

### なぜ Dependabot が自動修正できないのか

各パッケージを要求している親パッケージの制約と、依存ツリー内の他パッケージが
要求するバージョン系統が競合しており、Dependabot が解決策を導き出せない。

- **picomatch**: `@tailwindcss/cli`・`@testing-library/jest-dom`・
  `eslint-config-next`・`typescript-eslint` が `^4.0.3` を要求
- **minimatch**: `@graphql-codegen/cli`・`eslint-config-next`・
  `typescript-eslint` が `^9.0.5` または `^9.0.4` を要求
- **immutable**: `@graphql-codegen/cli`・`@graphql-codegen/client-preset` など
  複数の `@graphql-codegen/*` パッケージが `^3.7.6` を要求

---

## アプローチ

`frontend/package.json` に `resolutions` フィールドを追加して 3 パッケージを
固定し、yarn install で yarn.lock を更新する。

追加する内容:
```json
"resolutions": {
  "picomatch": "4.0.4",
  "minimatch": "9.0.7",
  "immutable": "3.8.3"
}
```

固定バージョンはいずれも親パッケージの semver 制約（`^4.0.3`・`^9.0.4`・`^3.7.6`）
を満たすパッチバージョンなので、親パッケージの動作を壊さない前提で固定できる。

yarn install 後、テストを実行してリグレッションがないことを確認してから次へ進む。

---

## 注意事項・想定される問題

- **yarn のバージョン確認が先決**: `resolutions` は yarn v1 の機能。
  yarn v2（berry）以降では `resolutions` でなく `.yarnrc.yml` の
  `packageExtensions` または `resolutions`（berry でも使えるが挙動が異なる）が
  必要になる場合がある。まず `yarn --version` で確認すること。

- **yarn.lock が更新されない場合**: `yarn install` だけでは lock が更新されない
  ケースがある。その場合は `yarn install --force` を試みること。

- **immutable の固定バージョンについて**: 親パッケージは `^3.7.6`（<4.0.0）を
  要求しているため、3.8.3 は範囲内だが、もし yarn が 5.x 系を解決しようとして
  競合する場合は、`resolutions` の値を `"~3.8.3"` ではなく `"3.8.3"` の完全固定に
  することで強制できる（既にそうなっているが念のため）。

- **minimatch の固定バージョンについて**: minimatch には 9.0.7 と別に 3.x 系も
  依存ツリー内に存在する可能性がある（Dependabot が「最新可能バージョンは 3.1.2」
  と表示していたことから、3.x 系を要求する別パッケージが存在する）。
  `resolutions` で `"minimatch": "9.0.7"` と指定すると 3.x を要求するパッケージにも
  9.0.7 が強制される恐れがある。yarn.lock を確認して minimatch の 3.x 系と 9.x 系
  が別エントリとして存在しているかを確認し、問題があれば
  `"minimatch@^9.0.0": "9.0.7"` のようにバージョン範囲付きで指定すること。

---

## 1. TL;DR

`frontend/yarn.lock` 内のトランジティブ依存として存在する 3 パッケージ（picomatch・minimatch・immutable）に High 脆弱性がある。
Dependabot が自動修正できない理由は、各パッケージの複数バージョン系列が依存ツリー内で共存しており、単純な upgrade が競合を引き起こすため。
`frontend/package.json` に yarn v1 の `resolutions` フィールドを追加し、バージョン範囲を限定したキーで 3 パッケージの脆弱バージョンのみを安全なバージョンに固定する。

---

## 前提とする既存仕様

- Yarn バージョン: **1.22.22**（v1）。`resolutions` フィールドをサポートする
- `frontend/package.json` には `resolutions` フィールドは現在存在しない
- `frontend/yarn.lock` 内の脆弱パッケージの現状:

| パッケージ | 脆弱系列 | 現在の解決バージョン | 安全系列 | 現在の解決バージョン |
|-----------|---------|-------------------|---------|-------------------|
| picomatch | 4.x（`^4.0.2`, `^4.0.3`） | 4.0.3 ← **要修正** | 2.x（`^2.x`） | 2.3.1（安全） |
| minimatch | 9.x（`^9.0.4`, `^9.0.5`） | 9.0.5 ← **要修正** | 3.x（`^3.x`） | 3.1.2（安全） |
| immutable | 3.x（`~3.7.6`） | 3.7.6 ← **要修正** | 5.x（`^5.0.2`） | 5.1.4（安全） |

各パッケージで脆弱系列と安全系列が yarn.lock 内に別エントリとして共存している。

---

## 2. 要件（Requirements）

### MUST（必達）
- Dependabot アラート #237（picomatch 4.0.3 → 4.0.4）を解消する
- Dependabot アラート #191（minimatch 9.0.5 → 9.0.7）を解消する
- Dependabot アラート #200（immutable 3.7.6 → 3.8.3）を解消する
- 既存テストがすべてグリーンのまま維持されること
- 安全系列（picomatch 2.x・minimatch 3.x・immutable 5.x）のバージョンが変化しないこと

### 非目標
- 直接依存パッケージのバージョンアップ
- 上記 3 件以外の Dependabot アラートへの対応
- yarn.lock の全面的な再生成

### 受け入れ基準
- `yarn.lock` 内の picomatch が `4.0.4`、minimatch が `9.0.7`、immutable が `3.8.3` に更新されている
- 安全系列（picomatch 2.3.1・minimatch 3.1.2・immutable 5.1.4）が変化していない
- `docker compose exec frontend yarn test` が全グリーン

---

## 3. 完成後の姿

### 3-1. 操作フロー

**ケース: resolutions 追加 → yarn install → lock 更新**
```
① frontend/package.json に resolutions フィールドを追加
② docker compose exec frontend yarn install を実行
③ yarn が resolutions の指定に従い、対象バージョン系列のみ固定バージョンに解決
④ yarn.lock が更新される（脆弱 3 パッケージのみ変化、他は変化なし）
⑤ テスト実行して全グリーン確認
```

UI 操作はなし（パッケージ管理のみの変更）。

### 3-2. データモデル

パッケージ変更のみのため、データモデル変更なし。

yarn.lock の変化予測:
- `picomatch@^4.0.2, picomatch@^4.0.3:` → `version "4.0.4"`（現在 4.0.3）
- `minimatch@^9.0.4, minimatch@^9.0.5:` → `version "9.0.7"`（現在 9.0.5）
- `immutable@~3.7.6:` → `version "3.8.3"`（現在 3.7.6）

変化しないエントリ:
- `picomatch@^2.0.4, ...` → `version "2.3.1"`（変化なし）
- `minimatch@^3.0.4, ...` → `version "3.1.2"`（変化なし）
- `immutable@^5.0.2:` → `version "5.1.4"`（変化なし）

### 3-3. クラス・API 設計

コード変更なし。`package.json` への `resolutions` フィールド追加のみ。

追加する `resolutions` の内容:
```json
"resolutions": {
  "picomatch@^4.0.0": "4.0.4",
  "minimatch@^9.0.0": "9.0.7",
  "immutable@^3.0.0": "3.8.3"
}
```

**キーにバージョン範囲を付ける理由**:
- 各パッケージに複数のバージョン系列が共存しているため、ベアキー（`"minimatch": "9.0.7"` など）を使うと安全系列（3.x・2.x・5.x）にも同じバージョンが強制され、依存パッケージが動作しなくなる恐れがある
- `"minimatch@^9.0.0": "9.0.7"` のようにバージョン範囲を限定することで、9.x を要求するパッケージのみ 9.0.7 に固定し、3.x は従来通り 3.1.2 のままにできる

---

## 4. なぜこの姿か（設計判断）

### 設計選択と理由

yarn v1 の `resolutions` フィールドを使うアプローチが最小変更で目的を達成できる。

- 親パッケージの直接アップグレードは試みていない。理由: 各親パッケージ（`@tailwindcss/cli`・`@graphql-codegen/cli` 等）は `^4.0.3`・`^9.0.5` のような範囲指定をしており、Dependabot がすでに「自動修正できない」と判断している状態。親を触ると連鎖的なバージョン競合が起きるリスクがある
- バージョン範囲付きキー（`"picomatch@^4.0.0": "4.0.4"`）を選択した理由: 同名パッケージの複数系列が共存している環境でベアキーを使うと、意図しない系列まで強制される。yarn v1 ドキュメントで `"package@range": "version"` 形式が明示的にサポートされている

### 代替案と棄却理由

- **案A: 親パッケージをアップグレードする**: 依存ツリーの連鎖的変更が発生し、影響範囲が予測困難。リグレッションリスクが高い
- **案B: ベアキーで resolutions を追加する（`"minimatch": "9.0.7"`）**: minimatch 3.x を要求するパッケージが 9.0.7 を強制されて破損する恐れがある。特に minimatch はメジャーバージョン間で API が変わっているため危険
- **案C: yarn.lock を手動編集する**: yarn install のたびに上書きされる。`resolutions` による管理の方が宣言的で再現性がある

---

## 5. リスクと対策

| リスク | 対策 |
|--------|------|
| `yarn install` 後も yarn.lock が更新されない | `yarn install --force` を試みる |
| バージョン範囲付きキーが想定通りに機能しない | yarn install 後に `yarn.lock` をグレップして実際の解決バージョンを確認する |
| immutable 3.8.3 が `~3.7.6` 制約（`>=3.7.6 <3.8.0`）を超えているため競合する | resolutions は制約を上書きする機能なので yarn v1 では強制できる。ただし、競合エラーが出た場合は `"immutable@~3.7.6": "3.8.3"` や親パッケージパス指定（`@graphql-codegen/cli/immutable`）に変更する |
| テストのリグレッション | 変更後に `docker compose exec frontend yarn test` で全テストグリーンを確認する |

---

## 6. テスト方針

- UI・ロジック変更なし。テスト追加・変更は不要
- 変更後に既存テスト全件を実行してリグレッションがないことを確認する
- 自動テストの網羅範囲外を補うため、メインケースの参照系をスクリーンショットで目視確認する
  - 確認観点: 「データが表示されているか」レベル（クラッシュなし・主要データ表示）
  - 確認対象: カレンダー画面・料理検索画面
  - 理由: immutable が `~3.7.6` の semver 範囲外（3.8.3）に強制されるため、`@graphql-codegen` 系への影響を目視で担保する

---

## （付録）変更点一覧

### フロントエンド
- `frontend/package.json`: `resolutions` フィールドを追加（3 パッケージ）
- `frontend/yarn.lock`: `yarn install` 実行後に自動更新（picomatch 4.x・minimatch 9.x・immutable 3.x のエントリ）
