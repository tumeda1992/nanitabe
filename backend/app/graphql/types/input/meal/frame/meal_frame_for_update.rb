module Types::Input::Meal::Frame
  class MealFrameForUpdate < Types::BaseInputObject
    argument :id, Int, required: true
    argument :name, String, required: true
  end
end
