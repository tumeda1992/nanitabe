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
        ::Dish.build_existing_root_from_id(dish_id)
      end
    end
  end
end
