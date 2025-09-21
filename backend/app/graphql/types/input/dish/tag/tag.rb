module Types::Input::Dish::Tag
  class Tag < ::Types::Input::CommandParamConvertableInput
    CONVERT_DESTINATION_CLASS = ::Business::Dish::Dish::Tag::Command::Params::Tag

    argument :id, Int, required: false
    argument :content, String, required: true

    def convert_to_command_param(use_food_module: false)
      if use_food_module
        ::Business::Food::Dish::Tag::Usecase::Params::Tag.new(**to_hash)
      else
        super()
      end
    end
  end
end
