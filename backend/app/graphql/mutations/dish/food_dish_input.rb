module Mutations::Dish
  # GraphQL入力からfoodのCommand引数への変換だけを担う。
  module FoodDishInput
    def self.source_relation(source, detail, source_id: nil)
      return unless detail.present? && source.present?

      ::Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
        source.type,
        source_id || source.id,
        detail.detail_value_of(source.type),
      )
    end

    def self.tags(tags)
      (tags || [])&.map { |tag| tag.convert_to_command_param(use_food_module: true) }
    end
  end
end
