module Business::Food::Meal::Frame::Pattern::Entry
  class Usecase::RemoveAllByPatternCommand < ::Business::Base::Command
    attribute :meal_frame_pattern_id, :integer
    validates :meal_frame_pattern_id, presence: true

    def call
      ::MealFramePatternEntry.where(meal_frame_pattern_id:).destroy_all
    end
  end
end
