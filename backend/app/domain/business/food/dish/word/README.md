料理についての言葉の正規化を行うモジュール。

「なす」「ナス」「茄子」などの揺れを吸収する。

具体的には、料理の名前などのカラムやフィールドについて、正規化後のものを提供し、
検索など、横断的に料理の名前を扱うときには正規化されたもので、利用しやすくする。
（元々の入力自体は正規化を行わず、自由に入力・表示をできるようにする）

処理が中心なので、エンティティは必要になるまで無理に持たない

---

# 管理画面
正規化ワードの管理画面は以下に配置：
- Controller: `backend/app/controllers/admin/food/dish/word/normalize_words_controller.rb`
- Views: `backend/app/views/admin/food/dish/word/normalize_words/`
- URL: `/admin/food/dish/word/normalize_words`

管理画面からは、このモジュールの以下のusecaseを呼び出す：
- `Usecase::AddCommand`: 正規化ワード追加
- `Usecase::UpdateCommand`: 正規化ワード更新
- `Usecase::RemoveCommand`: 正規化ワード削除
