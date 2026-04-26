module Business::Food::Meal::Frame::Entry
  class Usecase::RemoveCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :meal_frame_entry_id, :integer
    validates :meal_frame_entry_id, presence: true

    def call
      ::MealFrameEntry.find(meal_frame_entry_id).destroy!

      meal_frame_entry_id
    end
  end
end
