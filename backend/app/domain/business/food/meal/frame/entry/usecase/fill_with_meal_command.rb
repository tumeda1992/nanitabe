module Business::Food::Meal::Frame::Entry
  class Usecase::FillWithMealCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :meal_frame_entry_id, :integer
    validates :meal_frame_entry_id, presence: true

    attribute :meal_id, :integer
    validates :meal_id, presence: true

    def call
      root = ::MealFrameEntry.build_existing_root_from_id(meal_frame_entry_id)
      raise ActiveRecord::RecordNotFound, "MealFrameEntry with id #{meal_frame_entry_id} not found" if root.user_id != user_id

      ::MealFrame.where(user_id: user_id).find(root.meal_frame_id)
      ::Meal.where(user_id: user_id).find(meal_id)

      root.assign_meal(meal_id)
      ::MealFrameEntry.persist_from_food_meal_frame_entry_root(root)
      root
    end
  end
end
