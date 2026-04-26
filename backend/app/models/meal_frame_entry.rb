class MealFrameEntry < ApplicationRecord
  belongs_to :user
  belongs_to :meal_frame
  belongs_to :meal, optional: true

  class << self
    def build_existing_root_from_id(meal_frame_entry_id)
      record = find_by(id: meal_frame_entry_id)
      raise ActiveRecord::RecordNotFound, "MealFrameEntry with id #{meal_frame_entry_id} not found" unless record

      Business::Food::Meal::Frame::Entry::Root.new(
        id: record.id,
        user_id: record.user_id,
        meal_frame_id: record.meal_frame_id,
        date: record.date,
        meal_type: record.meal_type,
        meal_id: record.meal_id,
      )
    end

    def persist_from_food_meal_frame_entry_root(root)
      record = if root.id.present?
                 find_by(id: root.id)
               else
                 new(user_id: root.user_id, meal_frame_id: root.meal_frame_id)
               end
      record.persist_from_food_meal_frame_entry_root(root)

      record
    end
  end

  def persist_from_food_meal_frame_entry_root(root)
    self.date = root.date
    self.meal_type = root.meal_type
    self.meal_id = root.meal_id

    save!

    self
  end
end
