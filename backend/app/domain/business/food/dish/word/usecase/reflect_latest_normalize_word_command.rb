module Business::Food::Dish::Word
  class Usecase::ReflectLatestNormalizeWordCommand < ::Business::Base::Command
    def call
      # FIXME: いずれ非同期化

      ::Dish.all.pluck(:id).each do |dish_id|
        ::DishTag.build_existing_roots_of_dish(dish_id).each do |dish_tag_root|
          dish_tag_root.renormalize_content
          ::DishTag.persist_from_root(dish_tag_root, dish_id)
        end

        dish_root = ::Business::Food::Dish::Factory.build_existing_from_id(dish_id)
        dish_root.renormalize_name
        ::Dish.persist_from_food_dish_root(dish_root)
      end
    end
  end
end
