module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # TODO: remove me
    field :test_field, String, null: false,
                               description: "An example field added by the generator"
    def test_field
      "Hello World!"
    end

    field :meals_for_calender, resolver: Queries::Meal::MealsForCalender
    field :dish, resolver: Queries::Dish::Dish
    field :existing_dishes_for_registering_with_meal, resolver: Queries::Dish::ExistingDishesForRegisteringWithMeal
    field :dishes_per_source, resolver: Queries::Dish::DishesPerSource

    field :dish_source, resolver: Queries::Dish::Source::DishSource
    field :dish_sources, resolver: Queries::Dish::Source::DishSources
  end
end
