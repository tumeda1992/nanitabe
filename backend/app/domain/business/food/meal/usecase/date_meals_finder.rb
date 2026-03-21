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
                        :dish_tags,
                      ],
                    )
                    .order("meals.meal_type, dishes.meal_position")

      frame_entries = ::MealFrameEntry.where(user_id: access_user_id)
                                      .where(date: start_date..last_date)
                                      .joins(:meal_frame)
                                      .select(
                                        "meal_frame_entries.id",
                                        "meal_frame_entries.meal_frame_id",
                                        "meal_frame_entries.date",
                                        "meal_frame_entries.meal_type",
                                        "meal_frames.name AS meal_frame_name",
                                      )

      frame_entries_by_date = frame_entries.map do |entry|
        {
          id: entry.id,
          meal_frame_id: entry.meal_frame_id,
          meal_frame_name: entry.meal_frame_name,
          meal_type: entry.meal_type,
          date: entry.date,
        }
      end.group_by { |entry| entry[:date] }

      meals_by_date = meals.map do |meal|
        result_meal = meal.attributes
        result_meal[:dish] = meal.dish.to_searched_values

        result_meal.with_indifferent_access
      end.group_by { |meal| meal[:date] }

      all_dates = (meals_by_date.keys + frame_entries_by_date.keys).uniq.sort

      all_dates.map do |date|
        {
          date:,
          meals: meals_by_date[date] || [],
          frame_entries: frame_entries_by_date[date] || [],
        }
      end
    end
  end
end
