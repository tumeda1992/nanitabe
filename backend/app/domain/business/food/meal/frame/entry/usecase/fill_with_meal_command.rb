module Business::Food::Meal::Frame::Entry
  class Usecase::FillWithMealCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :meal_frame_entry_id, :integer
    validates :meal_frame_entry_id, presence: true

    attribute :meal_id, :integer
    validates :meal_id, presence: true

    def call
      ::Meal.transaction do
        ::Meal.where(user_id: user_id).lock.find(meal_id)
        entry = ::MealFrameEntry.where(user_id: user_id).lock.find(meal_frame_entry_id)
        ::MealFrame.where(user_id: user_id).find(entry.meal_frame_id)
        root = ::MealFrameEntry.build_existing_root_from_id(entry.id)

        Policy::AssignMealPolicy.ensure_available!(meal_id: meal_id, frame_entry_id: entry.id)
        root.assign_meal(meal_id)
        ::MealFrameEntry.persist_from_food_meal_frame_entry_root(root)
        root
      end
    end
  end
end
