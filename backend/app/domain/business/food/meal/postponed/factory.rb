module Business::Food::Meal::Postponed
  class Factory
    class << self
      def build(
        user_id,
        dish_id,
        meal_type,
        comment: nil
      )
        Root.new(
          user_id:,
          dish_id:,
          meal_type:,
          comment:,
        )
      end

      def build_existing_from_id(postponed_meal_id)
        ::PostponedMeal.build_existing_root_from_id(postponed_meal_id)
      end
    end
  end
end
