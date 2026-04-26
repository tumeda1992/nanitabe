module Types::Input::Meal::Frame::Pattern
  class MealFramePatternForCreate < Types::BaseInputObject
    argument :name, String, required: true
    argument :entries, [::Types::Input::Meal::Frame::Pattern::MealFramePatternEntryInput], required: true
  end
end
