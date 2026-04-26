class MealFramePatternEntry < ApplicationRecord
  belongs_to :meal_frame_pattern
  belongs_to :meal_frame

  validates :day_offset, presence: true, numericality: { greater_than: 0 }
  validates :meal_type, presence: true

  class << self
    def build_existing_root_from_id(meal_frame_pattern_entry_id)
      record = find_by(id: meal_frame_pattern_entry_id)
      raise ActiveRecord::RecordNotFound, "MealFramePatternEntry with id #{meal_frame_pattern_entry_id} not found" unless record

      Business::Food::Meal::Frame::Pattern::Entry::Root.new(
        id: record.id,
        meal_frame_pattern_id: record.meal_frame_pattern_id,
        day_offset: record.day_offset,
        meal_type: record.meal_type,
        meal_frame_id: record.meal_frame_id,
      )
    end

    def persist_from_food_meal_frame_pattern_entry_root(root)
      record = if root.id.present?
                 find_by(id: root.id)
               else
                 new(meal_frame_pattern_id: root.meal_frame_pattern_id, meal_frame_id: root.meal_frame_id)
               end
      record.persist_from_food_meal_frame_pattern_entry_root(root)

      record
    end
  end

  def persist_from_food_meal_frame_pattern_entry_root(root)
    self.day_offset = root.day_offset
    self.meal_type = root.meal_type

    save!

    self
  end
end
