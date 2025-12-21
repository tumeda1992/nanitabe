module Mutations::Meal
  class AddMealWithNewDishAndNewSource < ::Mutations::BaseMutation
    argument :dish, ::Types::Input::Dish::DishForCreate, required: true
    argument :meal, ::Types::Input::Meal::MealForCreate, required: true
    argument :dish_source, ::Types::Input::Dish::Source::SourceForCreate, required: true
    argument :dish_source_relation_detail, ::Types::Input::Dish::DishSourceRelation::DishSourceRelationDetail, required: false
    argument :dish_tags, [::Types::Input::Dish::Tag::Tag], required: false

    field :meal_id, Int, null: false
    field :dish_id, Int, null: false
    field :dish_source_id, Int, null: false

    def resolve(dish:, meal:, dish_source:, dish_source_relation_detail: nil, dish_tags: nil)
      ActiveRecord::Base.transaction do
        created_dish_source = ::Business::Food::Dish::Source::Usecase::AddCommand.call(
          user_id: context[:current_user_id],
          source_params: dish_source.convert_to_command_param(use_food_module: true),
        )

        dish_source_relation = if dish_source_relation_detail.present? && dish_source.present?
                                 ::Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
                                   dish_source.type,
                                   created_dish_source.id,
                                   dish_source_relation_detail.detail_value_of(dish_source.type),
                                 )
                               end

        created_dish = ::Business::Food::Dish::Usecase::AddCommand.call(
          user_id: context[:current_user_id],
          dish_params: dish.convert_to_command_param(use_food_module: true),
          dish_source_relation:,
          dish_tags: (dish_tags || [])&.map {|dish_tag| dish_tag.convert_to_command_param(use_food_module: true) },
        )

        created_meal = ::Business::Food::Meal::Usecase::AddCommand.call(
          user_id: context[:current_user_id],
          meal_params: meal.convert_to_command_param(use_food_module: true, dish_id: created_dish.id),
        )
        {
          meal_id: created_meal.id,
          dish_id: created_dish.id,
          dish_source_id: created_dish_source.id,
        }
      end
    end
  end
end
