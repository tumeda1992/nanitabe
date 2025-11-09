module Types::Input::Dish
  class DishForUpdate < ::Types::Input::CommandParamConvertableInput
    CONVERT_DESTINATION_CLASS = ::Business::Dish::Dish::Command::Params::DishForUpdate

    argument :id, Int, required: true
    argument :name, String, required: false
    argument :meal_position, Int, required: false
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
