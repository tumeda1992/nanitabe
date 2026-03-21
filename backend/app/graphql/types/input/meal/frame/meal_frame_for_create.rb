module Types::Input::Meal::Frame
  class MealFrameForCreate < Types::BaseInputObject
    argument :name, String, required: true
  end
end
