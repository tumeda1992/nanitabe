module Business::Food::Dish
  class Factory
    class << self
      def build(
        user_id,
        unnormalized_name,
        meal_position,
        comment: nil,
        source: nil,
        source_locator: nil,
        tags: []
      )
        source_id = if source.present?
                      Policy::AttachSourcePolicy.ensure!(source, source_locator)
                      source.id
                    end
        Business::Food::Dish::Root.new(
          user_id:,
          name: Name.initialize_and_normalize(unnormalized_name),
          meal_position:,
          comment:,
          source_id:,
          source_locator:,
          tags:
        )
      end

      def build_existing_from_id(dish_id)
        ::Dish.build_existing_root_from_id(dish_id)
      end
    end
  end
end
