module Business::Food::Meal::FrameEntry
  class Usecase::AddCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :meal_frame_id, :integer
    validates :meal_frame_id, presence: true

    attribute :date, :date
    validates :date, presence: true

    attribute :meal_type, :integer
    validates :meal_type, presence: true

    def call
      entry_root = Business::Food::Meal::FrameEntry::Root.new(
        user_id:,
        meal_frame_id:,
        date:,
        meal_type:,
      )

      entry_record = ::MealFrameEntry.persist_from_food_meal_frame_entry_root(entry_root)
      entry_root.set_id(entry_record.id)

      entry_root
    end
  end
end
