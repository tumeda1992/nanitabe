module Types::Input::Meal
  class MealForCreate < ::Types::Input::CommandParamConvertableInput
    CONVERT_DESTINATION_CLASS = ::Business::Dish::Meal::Command::Params::MealForCreate

    argument :date, GraphQL::Types::ISO8601Date, required: true
    argument :meal_type, Int, required: true
    argument :comment, String, required: false

    def convert_to_command_param(use_food_module: false, dish_id: nil)
      if use_food_module
        ::Business::Food::Meal::Usecase::Params::Meal.new(**to_hash, dish_id:)
      else
        super()
      end
    end
  end
end
