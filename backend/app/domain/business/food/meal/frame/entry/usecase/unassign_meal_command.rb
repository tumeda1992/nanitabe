module Business::Food::Meal::Frame::Entry
  class Usecase::UnassignMealCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :meal_frame_entry_id, :integer
    validates :meal_frame_entry_id, presence: true

    def call
      root = ::MealFrameEntry.build_existing_root_from_id(meal_frame_entry_id)
      root.unassign_meal
      ::MealFrameEntry.persist_from_food_meal_frame_entry_root(root)
      root
    end
  end
end
