module Types::Output::Dish::Word
  class NormalizeWord < ::Types::BaseObject
    field :id, Int, null: false
    field :entered_source, String, null: false
    field :entered_destination, String, null: false
    field :source, String, null: false
    field :destination, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
