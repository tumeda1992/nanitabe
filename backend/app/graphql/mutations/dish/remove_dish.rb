module Mutations::Dish
  class RemoveDish < ::Mutations::BaseMutation
    argument :dish_id, Int, required: true

    field :dish_id, Int, null: false

    def resolve(dish_id:)
      ActiveRecord::Base.transaction do
        ::Business::Food::Dish::Usecase::RemoveCommand.call(
          dish_id:,
          user_id: context[:current_user_id],
        )
        { dish_id: }
      end
    end
  end
end
