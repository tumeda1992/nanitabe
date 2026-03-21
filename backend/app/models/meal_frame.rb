class MealFrame < ApplicationRecord
  belongs_to :user
  has_many :meal_frame_entries

  class << self
    def build_existing_root_from_id(meal_frame_id)
      record = find_by(id: meal_frame_id)
      raise ActiveRecord::RecordNotFound, "MealFrame with id #{meal_frame_id} not found" unless record

      Business::Food::Meal::Frame::Root.new(
        id: record.id,
        user_id: record.user_id,
        name: record.name,
      )
    end

    def persist_from_food_meal_frame_root(root)
      record = if root.id.present?
                 find_by(id: root.id)
               else
                 new(user_id: root.user_id)
               end
      record.persist_from_food_meal_frame_root(root)

      record
    end
  end

  def persist_from_food_meal_frame_root(root)
    self.name = root.name

    save!

    self
  end
end
