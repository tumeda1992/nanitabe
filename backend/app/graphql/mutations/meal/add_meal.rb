module Mutations::Meal
  class AddMeal < ::Mutations::BaseMutation
    argument :dish_id, Int, required: true
    argument :meal, ::Types::Input::Meal::MealForCreate, required: true

    field :meal_id, Int, null: false

    def resolve(dish_id:, meal:)
      ActiveRecord::Base.transaction do
        created_meal = ::Business::Food::Meal::Usecase::AddCommand.call(
          user_id: context[:current_user_id],
          meal_params: meal.convert_to_command_param(use_food_module: true, dish_id:),
        )
        { meal_id: created_meal.id }
      end
    end
  end
end
