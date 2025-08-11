module Mutations::Dish::Source
  class AddSource < ::Mutations::BaseMutation
    argument :dish_source, ::Types::Input::Dish::Source::SourceForCreate, required: true

    field :dish_source_id, Int, null: false

    def resolve(dish_source:)
      ActiveRecord::Base.transaction do
        created_dish_source = ::Business::Dish::Dish::Source::Command::AddCommand.call(
          user_id: context[:current_user_id],
          dish_source_for_create: dish_source.convert_to_command_param,
        )
        # created_dish_source = ::Business::Food::Dish::Source::Usecase::AddCommand.call(
        #   user_id: context[:current_user_id],
        #   dish_params: dish_source.convert_to_command_param,
        # )

        {
          dish_source_id: created_dish_source.id,
        }
      end
    end
  end
end
