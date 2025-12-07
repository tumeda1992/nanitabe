module Business::Food::Meal
  class Usecase::DateMealsFinder < Business::Base::Finder
    attribute :access_user_id, :integer
    validates :access_user_id, presence: true
    attribute :start_date, :date
    validates :start_date, presence: true
    attribute :last_date, :date
    validates :last_date, presence: true

    def fetch
      meals = ::Meal.where(user_id: access_user_id)
                    .where(date: start_date..last_date)
                    .left_joins(:dish)
                    .includes(
                      dish: [
                        :dish_source_relation,
                        :dish_source,
                        :dish_evaluation,
                        :dish_tags
                      ]
                    )
                    .order("meals.meal_type, dishes.meal_position")

      meals.map do |meal|
        result_meal = meal.attributes
        result_meal[:dish] = meal.dish.to_searched_values

        result_meal.with_indifferent_access
      end.group_by { |meal| meal[:date] }
           .map do |(date, meals)|
        {
          date:,
          meals:,
        }
      end || []
    end
  end
end
