module Types::Input::Meal::FrameEntry
  class MealFrameEntryForCreate < Types::BaseInputObject
    argument :meal_frame_id, Int, required: true
    argument :date, GraphQL::Types::ISO8601Date, required: true
    argument :meal_type, Int, required: true
  end
end
