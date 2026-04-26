module Business::Food::Meal::Frame::Pattern
  class Usecase::RemoveCommand < ::Business::Base::Command
    attribute :meal_frame_pattern_id, :integer
    validates :meal_frame_pattern_id, presence: true

    def call
      ::MealFramePattern.find(meal_frame_pattern_id).destroy!

      meal_frame_pattern_id
    end
  end
end
