module Business::Food::Meal
  class Usecase::SwapMealsBetweenDaysCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :date1, :date
    validates :date1, presence: true

    attribute :date2, :date
    validates :date2, presence: true

    def call
      date1_meal_roots = ::Meal.fetch_by_date(date1)
      date2_meal_roots = ::Meal.fetch_by_date(date2)

      date1_meal_roots.each do |date1_meal_root|
        date1_meal_root.reschedule(date2)
        ::Meal.persist_from_food_meal_root(date1_meal_root)
      end

      date2_meal_roots.each do |date2_meal_root|
        date2_meal_root.reschedule(date1)
        ::Meal.persist_from_food_meal_root(date2_meal_root)
      end

      date1_meal_roots.concat(date2_meal_roots)
    end
  end
end
