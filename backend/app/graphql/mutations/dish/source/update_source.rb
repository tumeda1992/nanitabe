module Mutations::Dish::Source
  class UpdateSource < ::Mutations::BaseMutation
    argument :dish_source, ::Types::Input::Dish::Source::SourceForUpdate, required: true

    field :dish_source_id, Int, null: false

    def resolve(dish_source:)
      ActiveRecord::Base.transaction do
        ::Business::Dish::Dish::Source::Command::UpdateCommand.call(
          user_id: context[:current_user_id],
          dish_source_for_update: ::Business::Dish::Dish::Source::Command::Params::SourceForUpdate.new(
            id: dish_source.id,
            name: dish_source.name,
            type: dish_source.type,
            comment: dish_source.comment,
          ),
        )

        ::Business::Food::Dish::Source::Usecase::UpdateCommand.call(
          user_id: context[:current_user_id],
          source_params: dish_source.convert_to_command_param(use_food_module: true),
        )

        {
          dish_source_id: dish_source.id,
        }
      end
    end
  end
end
