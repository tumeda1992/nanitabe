module Business::Food::Dish
  class Factory
    class << self
      def build(user_id, name, meal_position, comment: nil)
        dish = Business::Food::Dish::Root.new(
          user_id:,
          name:,
          normalized_name: Business::Dish::Word::Normalize::Command::NormalizeCommand.call(string_sequence: name),
          meal_position:,
          comment:
        )
        dish.validate!
        dish
      end

      def build_existing_from_id(dish_id)
        dish_record = ::Dish.find(dish_id)
        return if dish_record.blank?

        build_existing_from_params(dish_record.attributes)
      end

      private

      def build_existing_from_params(dish_params)
        Business::Food::Dish::Root.new(
          id: dish_params["id"],
          user_id: dish_params["user_id"],
          name: dish_params["name"],
          normalized_name: dish_params["normalized_name"],
          meal_position: dish_params["meal_position"],
          comment: dish_params["comment"]
        )
      end
    end
  end
end
