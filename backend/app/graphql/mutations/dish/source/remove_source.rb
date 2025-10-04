module Mutations::Dish::Source
  class RemoveSource < ::Mutations::BaseMutation
    argument :dish_source_id, Int, required: true

    field :dish_source_id, Int, null: false

    def resolve(dish_source_id:)
      ActiveRecord::Base.transaction do
        ::Business::Food::Dish::Source::Usecase::RemoveCommand.call(
          user_id: context[:current_user_id],
          source_id: dish_source_id,
          )
        { dish_source_id: }
      end
    end
  end
end
