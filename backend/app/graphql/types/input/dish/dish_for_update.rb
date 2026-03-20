module Types::Input::Dish
  class DishForUpdate < ::Types::Input::CommandParamConvertableInput
    CONVERT_DESTINATION_CLASS = ::Business::Dish::Dish::Command::Params::DishForUpdate

    argument :id, Int, required: true
    argument :name, String, required: false
    argument :meal_position, Int, required: false
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
