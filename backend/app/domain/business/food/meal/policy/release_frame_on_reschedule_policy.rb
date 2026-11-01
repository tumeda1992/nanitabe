module Business::Food::Meal
  class Policy::ReleaseFrameOnReschedulePolicy
    def self.required?(previous_date:, previous_meal_type:, date:, meal_type:)
      previous_date != date || previous_meal_type != meal_type
    end
  end
end
