module Business::Food::Meal
  class DateMealsFinder < Business::Base::Finder
    attribute :access_user_id, :integer
    validates :access_user_id, presence: true
    attribute :start_date, :date
    validates :start_date, presence: true
    attribute :last_date, :date
    validates :last_date, presence: true

    def fetch
      meals = ::Meal.where(user_id: access_user_id)
                    .where(date: start_date..last_date)
                    .eager_load(:dish)
                    .eager_load(dish: :dish_evaluation)
                    .eager_load(dish: :dish_source)
                    .eager_load(dish: :dish_source_relation)
                    .eager_load(dish: :dish_tags)
                    .order("meals.meal_type, dishes.meal_position")

      meals.map do |meal|
        result_meal = meal.attributes
        result_meal[:dish] = meal.dish.attributes

        dish_relation = if meal.dish&.dish_source_relation.present? && meal.dish&.dish_source.present?
                          {
                            dish_id: meal.dish.dish_source_relation.dish_id,
                            type: meal.dish.dish_source.type,
                            source_name: meal.dish.dish_source.name,
                            dish_source_id: meal.dish.dish_source.id,
                            recipe_book_page: meal.dish.dish_source_relation.recipe_book_page,
                            recipe_website_url: meal.dish.dish_source_relation.recipe_website_url,
                            recipe_source_memo: meal.dish.dish_source_relation.recipe_source_memo,
                          }
                        end
        result_meal[:dish][:dish_source_relation] = dish_relation
        result_meal[:dish][:evaluation_score] = meal.dish.dish_evaluation&.score
        result_meal[:dish][:tags] = (meal.dish.dish_tags.presence || []).map {|tag| tag.attributes}

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
