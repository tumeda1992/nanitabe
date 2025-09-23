module Business::Dish::Meal
  class Command::SwapMealsBetweenDaysCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :date1, :date
    validates :date1, presence: true

    attribute :date2, :date
    validates :date2, presence: true

    def call
      date1_meals = Repository.fetch_by_date(date1)
      date2_meals = Repository.fetch_by_date(date2)

      date1_meals.each do |date1_meal|
        date1_meal.date = date2
        Repository.update(date1_meal, user_id)
      end

      date2_meals.each do |date2_meal|
        date2_meal.date = date1
        Repository.update(date2_meal, user_id)
      end

      date1_meals.concat(date2_meals)
    end
  end
end