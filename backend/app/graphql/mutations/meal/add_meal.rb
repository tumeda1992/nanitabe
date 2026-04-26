module Mutations::Meal
  class AddMeal < ::Mutations::BaseMutation
    argument :dish_id, Int, required: true
    argument :meal, ::Types::Input::Meal::MealForCreate, required: true
    argument :frame_entry_id, Int, required: false

    field :meal_id, Int, null: false

    def resolve(dish_id:, meal:, frame_entry_id: nil)
      ActiveRecord::Base.transaction do
        created_meal = ::Business::Food::Meal::Usecase::AddCommand.call(
          user_id: context[:current_user_id],
          meal_params: meal.convert_to_command_param(use_food_module: true, dish_id:),
        )

        if frame_entry_id
          ::Business::Food::Meal::Frame::Entry::Usecase::FillWithMealCommand.call(
            user_id: context[:current_user_id],
            meal_frame_entry_id: frame_entry_id,
            meal_id: created_meal.id,
          )
        end

        { meal_id: created_meal.id }
      end
    end
  end
end
