class TypeAny < ActiveModel::Type::Value
  def cast_value(value)
    value
  end
end

ActiveModel::Type.register(:any, TypeAny)

# 注意
# attributeメソッドで定義されたフィールドについて、
# 型定義は型が違ったらエラーになるわけではなく、キャストされるだけ。
# 値が入った時点ではキャストされず、値が参照されたタイミングでキャストされる（定義している例外は参照時に発生）。
# しかし、nilの場合にはキャストメソッドが発火されないので注意 https://github.com/rails/rails/blob/main/activemodel/lib/active_model/type/value.rb#L58
# CommandParamsArrayTypeのように、nilも許容したくないためにapp/models/disallow_nil_validator.rbというカスタムバリデーションを作成
# （いつかQiitaに書く）

# app配下で定義したかったがinitializersではまだapp配下のオートロードとかが済んでいないためこちらで定義
class CommandParamsType < ActiveModel::Type::Value
  def cast_value(value)
    raise "フィールドの値が不正です。" if value.invalid?

    value
  end
end

ActiveModel::Type.register(:command_params, CommandParamsType)

class CommandParamsArrayType < ActiveModel::Type::Value
  def cast_value(array_value)
    # nilはvalidatesのdisallow_nilで除外
    raise "値が配列ではありません" if array_value.class != Array

    array_value.each do |value|
      raise "フィールドの値が不正です。" if value.invalid?
    end

    array_value
  end
end

ActiveModel::Type.register(:command_params_array, CommandParamsArrayType)

# TODO: 動いた後にlintで怒られたら上に移す
# requireしないと認識されない。噂だとdomainsと複数形のディレクトリにしたらいけるかもみたいな話を聞いた
require_relative "../../app/domain/business/food/dish/source/type"
ActiveModel::Type.register(:dish_source_type, ::Business::Food::Dish::Source::Type::DishSourceTypeForActiveModel)

require_relative "../../app/domain/business/food/dish/name"
ActiveModel::Type.register(:dish_name, ::Business::Food::Dish::Name::DishNameForActiveModel)
