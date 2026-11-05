module Types::Output::Dish
  module EssentialDish
    include Types::BaseInterface

    field :id, Int, null: false
    field :name, String, null: false
    field :meal_position, Int, null: false
    field :comment, String, null: true

    field :evaluation_score, Float, null: true
    field :tags, [DishTag], null: true

    field :dish_source_relation, DishSourceRelation, null: true
  end
end
