module Mutations::Dish
  class AddDishWithNewSource < ::Mutations::BaseMutation
    argument :dish, ::Types::Input::Dish::DishForCreate, required: true
    argument :dish_source, ::Types::Input::Dish::Source::SourceForCreate, required: true
    argument :dish_source_relation_detail, ::Types::Input::Dish::DishSourceRelation::DishSourceRelationDetail, required: false
    argument :dish_tags, [::Types::Input::Dish::Tag::Tag], required: false

    field :dish_id, Int, null: false
    field :dish_source_id, Int, null: false

    def resolve(dish:, dish_source:, dish_source_relation_detail: nil, dish_tags: nil)
      ActiveRecord::Base.transaction do
        created_dish_source = ::Business::Food::Dish::Source::Usecase::AddCommand.call(
          user_id: context[:current_user_id],
          source_params: dish_source.convert_to_command_param(use_food_module: true),
        )

        dish_source_relation = ::Mutations::Dish::FoodDishInput.source_relation(
          dish_source, dish_source_relation_detail, source_id: created_dish_source.id
        )

        created_dish = ::Business::Food::Dish::Usecase::AddCommand.call(
          user_id: context[:current_user_id],
          dish_params: dish.convert_to_command_param(use_food_module: true),
          dish_source_relation:,
          dish_tags: ::Mutations::Dish::FoodDishInput.tags(dish_tags),
        )

        {
          dish_id: created_dish.id,
          dish_source_id: created_dish_source.id,
        }
      end
    end
  end
end
