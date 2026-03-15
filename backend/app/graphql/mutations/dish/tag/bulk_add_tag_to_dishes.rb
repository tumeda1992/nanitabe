module Mutations::Dish::Tag
  class BulkAddTagToDishes < ::Mutations::BaseMutation
    argument :dish_ids, [Int], required: true
    argument :tag, String, required: true

    field :dish_ids, [Int], null: false

    def resolve(dish_ids:, tag:)
      ::Business::Food::Dish::Tag::Usecase::BulkAddTagToDishesCommand.call(
        user_id: context[:current_user_id],
        dish_ids:,
        tag_content: tag,
      )

      { dish_ids: }
    end
  end
end
