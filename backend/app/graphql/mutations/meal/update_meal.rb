module Mutations::Meal
  class UpdateMeal < ::Mutations::BaseMutation
    argument :meal, ::Types::Input::Meal::MealForUpdate, required: true
    argument :dish_id, Int, required: true

    field :meal_id, Int, null: false

    def resolve(meal:, dish_id:)
      ActiveRecord::Base.transaction do
        ::Business::Food::Meal::Usecase::UpdateCommand.call(
          user_id: context[:current_user_id],
          meal_params: meal.convert_to_command_param(use_food_module: true, dish_id:),
        )
      end
      { meal_id: meal.id }
    end
  end
end
