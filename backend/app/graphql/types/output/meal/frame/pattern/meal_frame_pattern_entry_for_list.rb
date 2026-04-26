module Types::Output::Meal::Frame::Pattern
  class MealFramePatternEntryForList < Types::BaseObject
    field :id, Int, null: false
    field :day_offset, Int, null: false
    field :meal_type, Int, null: false
    field :meal_frame_id, Int, null: false
    field :meal_frame_name, String, null: false

    def meal_frame_name
      ::MealFrame.find_by(id: object[:meal_frame_id])&.name || ""
    end
  end
end
