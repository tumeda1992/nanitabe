module Business::Food::Meal
  class Factory
    class << self
      def build(
        user_id,
        dish_id,
        date,
        meal_type,
        comment: nil
      )
        Policy::AttachDishPolicy.ensure!(dish_id)
        Root.new(
          user_id:,
          dish_id:,
          date:,
          meal_type:,
          comment:,
        )
      end

      def build_existing_from_id(meal_id)
        ::Meal.build_existing_root_from_id(meal_id)
      end
    end
  end
end
