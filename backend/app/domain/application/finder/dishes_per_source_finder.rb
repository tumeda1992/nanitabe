module Application::Finder
  class DishesPerSourceFinder < Business::Base::Finder
    attribute :access_user_id, :integer
    validates :access_user_id, presence: true

    # NOTE: この作りについて、直せれば直したけど、オプショナルなFinderだから、他を直したときについでに直すくらいで
    def fetch
      dishes = ::Dish.where(user_id: access_user_id)
                     .eager_load(:meals)
                     .eager_load(:dish_source_relation)
                     .eager_load(dish_source_relation: :dish_source)
                     .left_outer_joins(:dish_tags)
                     .left_outer_joins(:dish_evaluation)
                     .order("dish_evaluations.score DESC")
      dishes_per_source = group_rows_by_key(dishes, :dish_source, :dishes) do |dish|
        dish&.dish_source_relation&.dish_source
      end

      # パフォーマンス気になったら、取得済みのdish_sourceを先に取って、DishSourceからはそれ以外を取得して、取得したやつ全詰めとかで対応
      dishes_per_source = ::DishSource.where(user_id: access_user_id).each_with_object(dishes_per_source) do |dish_source, result_dishes_per_source|
        dish_source_fetched = result_dishes_per_source.any? do |dish|
          dish[:dish_source]&.id == dish_source.id
        end
        next result_dishes_per_source if dish_source_fetched

        result_dishes_per_source.push({ dish_source:, dishes: [] })
      end

      dishes_per_source.map do |dish_per_source|
        {
          dish_source: dish_per_source[:dish_source],
          dishes_per_meal_position: group_rows_by_key(dish_per_source[:dishes], :meal_position, :dishes),
        }
      end
    end
  end
end
