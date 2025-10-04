module Types::Input::Dish::Source
  class SourceForUpdate < ::Types::BaseInputObject
    argument :id, Int, required: true
    argument :name, String, required: false
    argument :type, Int, required: false
    argument :comment, String, required: false

    def convert_to_command_param(use_food_module: false)
      if use_food_module
        ::Business::Food::Dish::Source::Usecase::Params::Source.new(**to_hash)
      else
        super()
      end
    end
  end
end
