module Business::Food::Meal::Frame::Pattern::Entry
  class Usecase::AddCommand < ::Business::Base::Command
    attribute :meal_frame_pattern_id, :integer
    validates :meal_frame_pattern_id, presence: true

    attribute :day_offset, :integer
    validates :day_offset, presence: true, numericality: { greater_than: 0 }

    attribute :meal_type, :integer
    validates :meal_type, presence: true

    attribute :meal_frame_id, :integer
    validates :meal_frame_id, presence: true

    def call
      entry_root = Business::Food::Meal::Frame::Pattern::Entry::Root.new(
        meal_frame_pattern_id:,
        day_offset:,
        meal_type:,
        meal_frame_id:,
      )

      entry_record = ::MealFramePatternEntry.persist_from_food_meal_frame_pattern_entry_root(entry_root)
      entry_root.set_id(entry_record.id)

      entry_root
    end
  end
end
