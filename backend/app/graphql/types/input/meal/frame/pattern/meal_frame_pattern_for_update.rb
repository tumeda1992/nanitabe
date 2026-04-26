module Types::Input::Meal::Frame::Pattern
  class MealFramePatternForUpdate < Types::BaseInputObject
    argument :id, Int, required: true
    argument :name, String, required: true
    argument :entries, [::Types::Input::Meal::Frame::Pattern::MealFramePatternEntryInput], required: true
  end
end
