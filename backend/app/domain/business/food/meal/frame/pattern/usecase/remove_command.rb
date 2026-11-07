module Business::Food::Meal::Frame::Pattern
  class Usecase::RemoveCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :meal_frame_pattern_id, :integer
    validates :meal_frame_pattern_id, presence: true

    def call
      ::MealFramePattern.where(user_id: user_id).find(meal_frame_pattern_id).destroy!

      meal_frame_pattern_id
    end
  end
end
