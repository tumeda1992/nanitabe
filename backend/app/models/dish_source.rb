class DishSource < ApplicationRecord
  belongs_to :user
  self.inheritance_column = :_type_disabled

  class << self
    def build_from_food_dish_source_root(food_dish_source_root)
      new(
        id: food_dish_source_root.id,
        user_id: food_dish_source_root.user_id,
        name: food_dish_source_root.name,
        type: food_dish_source_root.type.value,
        comment: food_dish_source_root.comment
      )
    end
  end
end
