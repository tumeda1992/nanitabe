class MealFramePattern < ApplicationRecord
  belongs_to :user
  has_many :meal_frame_pattern_entries, dependent: :destroy

  validates :name, presence: true

  class << self
    def build_existing_root_from_id(meal_frame_pattern_id)
      record = find_by(id: meal_frame_pattern_id)
      raise ActiveRecord::RecordNotFound, "MealFramePattern with id #{meal_frame_pattern_id} not found" unless record

      Business::Food::Meal::Frame::Pattern::Root.new(
        id: record.id,
        user_id: record.user_id,
        name: record.name,
      )
    end

    def persist_from_food_meal_frame_pattern_root(root)
      record = if root.id.present?
                 find_by(id: root.id)
               else
                 new(user_id: root.user_id)
               end
      record.persist_from_food_meal_frame_pattern_root(root)

      record
    end
  end

  def persist_from_food_meal_frame_pattern_root(root)
    self.name = root.name

    save!

    self
  end
end
