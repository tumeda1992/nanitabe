module Types::Input::Dish
  class DishForCreate < ::Types::Input::CommandParamConvertableInput
    CONVERT_DESTINATION_CLASS = ::Business::Dish::Dish::Command::Params::DishForCreate

    argument :name, String, required: true
    argument :meal_position, Int, required: true
    argument :comment, String, required: false
    argument :dish_effort_level_id, Int, required: false

    def convert_to_command_param(use_food_module: false)
      if use_food_module
        params = to_hash
        params[:effort_level_id] = params.delete(:dish_effort_level_id)
        ::Business::Food::Dish::Usecase::Params::Dish.new(**params)
      else
        super()
      end
    end
  end
end
