class Meal < ApplicationRecord
  belongs_to :user
  belongs_to :dish
  has_one :meal_frame_entry, dependent: :nullify

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
        comment: meal_record.comment,
      )
    end

    def fetch_by_date(date, user_id:)
      meal_records = where(date: date, user_id: user_id)
      return [] if meal_records.blank?

      meal_records.map { |meal_record| build_existing_root_from_id(meal_record.id) }
    end

    def persist_from_food_meal_root(food_meal_root)
      meal_record = if food_meal_root.id.present?
                      find_by(id: food_meal_root.id)
                    else
                      new(user_id: food_meal_root.user_id)
                    end
      meal_record.persist_from_food_meal_root(food_meal_root)

      meal_record
    end
  end

  def persist_from_food_meal_root(food_meal_root)
    self.dish_id = food_meal_root.dish_id
    self.date = food_meal_root.date
    self.meal_type = food_meal_root.meal_type
    self.comment = food_meal_root.comment

    save_with_frame_release!

    self
  end

  def save_with_frame_release!
    release_frame = persisted? && Business::Food::Meal::Policy::ReleaseFrameOnReschedulePolicy.required?(
      previous_date: date_in_database,
      previous_meal_type: meal_type_in_database,
      date: date,
      meal_type: meal_type,
    )

    self.class.transaction do
      result = save!
      if release_frame
        MealFrameEntry.where(meal_id: id).update_all(meal_id: nil)
        association(:meal_frame_entry).reset
      end
      result
    end
  end
end
