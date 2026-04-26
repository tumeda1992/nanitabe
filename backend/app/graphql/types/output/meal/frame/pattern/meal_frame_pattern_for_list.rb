module Types::Output::Meal::Frame::Pattern
  class MealFramePatternForList < Types::BaseObject
    field :id, Int, null: false
    field :name, String, null: false
    field :entries, [::Types::Output::Meal::Frame::Pattern::MealFramePatternEntryForList], null: false

    def entries
      ::MealFramePatternEntry.where(meal_frame_pattern_id: object[:id]).map do |entry|
        {
          id: entry.id,
          day_offset: entry.day_offset,
          meal_type: entry.meal_type,
          meal_frame_id: entry.meal_frame_id,
        }
      end
    end
  end
end
