module Types::Input::Dish
  class DishForCreate < ::Types::Input::CommandParamConvertableInput
    CONVERT_DESTINATION_CLASS = ::Business::Dish::Dish::Command::Params::DishForCreate

    argument :name, String, required: true
    argument :meal_position, Int, required: true
    argument :comment, String, required: false

    def convert_to_command_param(use_food_module: false)
      if use_food_module
        ::Business::Food::Dish::Usecase::Params::Dish.new(**to_hash)
      else
        super()
      end
    end
  end
end
