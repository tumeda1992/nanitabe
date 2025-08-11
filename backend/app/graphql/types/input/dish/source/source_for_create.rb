module Types::Input::Dish::Source
  class SourceForCreate < ::Types::Input::CommandParamConvertableInput
    CONVERT_DESTINATION_CLASS = ::Business::Dish::Dish::Source::Command::Params::SourceForCreate
    # CONVERT_DESTINATION_CLASS = ::Business::Food::Dish::Source::Usecase::Params::Source

    argument :name, String, required: true
    argument :type, Int, required: true
    argument :comment, String, required: false
  end
end
