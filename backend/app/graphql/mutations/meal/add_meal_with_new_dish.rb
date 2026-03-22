module Mutations::Meal
  class AddMealWithNewDish < ::Mutations::BaseMutation
    argument :dish, ::Types::Input::Dish::DishForCreate, required: true
    argument :dish_source, ::Types::Input::Dish::Source::SourceForRead, required: false
    argument :dish_source_relation_detail, ::Types::Input::Dish::DishSourceRelation::DishSourceRelationDetail, required: false
    argument :dish_tags, [::Types::Input::Dish::Tag::Tag], required: false
    argument :meal, ::Types::Input::Meal::MealForCreate, required: true
    argument :frame_entry_id, Int, required: false

    field :meal_id, Int, null: false
    field :dish_id, Int, null: false

    def resolve(dish:, meal:, dish_source: nil, dish_source_relation_detail: nil, dish_tags: nil, frame_entry_id: nil)
      ActiveRecord::Base.transaction do
        dish_source_relation = if dish_source_relation_detail.present? && dish_source.present?
                                 ::Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
                                   dish_source.type,
                                   dish_source.id,
                                   dish_source_relation_detail.detail_value_of(dish_source.type),
                                 )
                               end

        created_dish = ::Business::Food::Dish::Usecase::AddCommand.call(
          user_id: context[:current_user_id],
          dish_params: dish.convert_to_command_param(use_food_module: true),
          dish_source_relation:,
          dish_tags: (dish_tags || [])&.map { |dish_tag| dish_tag.convert_to_command_param(use_food_module: true) },
        )

        created_meal = ::Business::Food::Meal::Usecase::AddCommand.call(
          user_id: context[:current_user_id],
          meal_params: meal.convert_to_command_param(use_food_module: true, dish_id: created_dish.id),
        )

        if frame_entry_id
          ::Business::Food::Meal::FrameEntry::Usecase::FillWithMealCommand.call(
            user_id: context[:current_user_id],
            meal_frame_entry_id: frame_entry_id,
            meal_id: created_meal.id,
          )
        end

        {
          meal_id: created_meal.id,
          dish_id: created_dish.id,
        }
      end
    end
  end
end
