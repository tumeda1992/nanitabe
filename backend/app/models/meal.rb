class Meal < ApplicationRecord
  belongs_to :user
  belongs_to :dish

  class << self
    def build_existing_root_from_id(meal_id)
      meal_record = find_by(id: meal_id)
      raise ActiveRecord::RecordNotFound, "Meal with id #{meal_id} not found" unless meal_record

      Business::Food::Meal::Root.new(
        id: meal_record.id,
        user_id: meal_record.user_id,
        dish_id: meal_record.dish_id,
        date: meal_record.date,
        meal_type: meal_record.meal_type,
        comment: meal_record.comment
      )
    end
  end
end
