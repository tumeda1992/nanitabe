module Business::Food::Dish
  class Usecase::DishSearcher < Business::Base::Finder
    attribute :access_user_id, :integer
    validates :access_user_id, presence: true

    attribute :search_string, :string
    attribute :meal_position, :integer
    attribute :registered_with_meal, :boolean

    # 食事登録時に、すでにその食事に登録されている料理を先頭に置くための値。
    # 条件を厳しくしたときに、その検索条件にヒットしなくても先頭に置くために使う。
    attribute :dish_id_registered_with_meal, :integer

    # 数が多くなってきたら、20個くらいしか出さずに、続きはGraphQLのページング機能で出す
    def fetch
      registered_dish_with_meal = if dish_id_registered_with_meal.present?
                                    ::Dish.where(id: dish_id_registered_with_meal)
                                          .with_search_relations
                                          .search_output
                                          .first
                                  end

      dish_relation = ::Dish.for_user(access_user_id)
                            .with_search_relations
                            .search_output

      if registered_dish_with_meal.present?
        dish_relation = dish_relation.where.not(id: registered_dish_with_meal.id)
      end

      if search_string.present?
        normalized_search_string = ::Business::Dish::Word::Normalize::Command::NormalizeCommand.call(string_sequence: search_string)
        dish_relation = normalized_search_string.split.reduce(dish_relation) do |relation, word|
          relation.merge(
            Dish.matching_normalized_name(word)
                .or(::DishSource.matching_normalized_name(word))
                .or(::DishTag.matching_normalized_content(word)),
            )
        end
      end

      dish_relation = dish_relation.where(meal_position: meal_position) if meal_position.present?

      unless registered_with_meal.nil? # boolean値なので、blank?ではなくnil?で判定
        dish_relation = if registered_with_meal
                          dish_relation.having("COUNT(meals.id) > 0")
                        else
                          dish_relation.having("COUNT(meals.id) = 0")
                        end
      end

      [registered_dish_with_meal, dish_relation].flatten.compact
    end
  end
end
