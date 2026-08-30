class PostponedMeal < ApplicationRecord
  belongs_to :user
  belongs_to :dish

  class << self
    def build_existing_root_from_id(postponed_meal_id)
      postponed_meal_record = find_by(id: postponed_meal_id)
      unless postponed_meal_record
        raise ActiveRecord::RecordNotFound, "PostponedMeal with id #{postponed_meal_id} not found"
      end

      Business::Food::Meal::Postponed::Root.new(
        id: postponed_meal_record.id,
        user_id: postponed_meal_record.user_id,
        dish_id: postponed_meal_record.dish_id,
        meal_type: postponed_meal_record.meal_type,
        comment: postponed_meal_record.comment,
      )
    end

    def persist_from_food_meal_postponed_root(food_meal_postponed_root)
      postponed_meal_record = if food_meal_postponed_root.id.present?
                                find_by(id: food_meal_postponed_root.id)
                              else
                                new(user_id: food_meal_postponed_root.user_id)
                              end
      postponed_meal_record.persist_from_food_meal_postponed_root(food_meal_postponed_root)

      postponed_meal_record
    end
  end

  def persist_from_food_meal_postponed_root(food_meal_postponed_root)
    self.dish_id = food_meal_postponed_root.dish_id
    self.meal_type = food_meal_postponed_root.meal_type
    self.comment = food_meal_postponed_root.comment

    save!

    self
  end
end
