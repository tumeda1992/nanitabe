module Business::Dish::Dish
  class Command::UpdateWithNewSourceCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_for_update, :command_params
    validates :dish_for_update, presence: true

    attribute :dish_source_for_create, :command_params
    validates :dish_source_for_create, presence: true

    attribute :dish_source_relation_detail_value, :any
    validates :dish_source_relation_detail_value, presence: false

    attribute :dish_tags, :command_params_array
    validates :dish_tags, presence: false

    def call
      source_module = ::Business::Dish::Dish::Source
      created_dish_source = source_module::Command::AddCommand.call(
        user_id:,
        dish_source_for_create:,
      )

      dish_source_relation = Command::Params::DishSourceRelation.build_relation(
        created_dish_source.type,
        dish_for_update.id,
        created_dish_source.id,
        dish_source_relation_detail_value,
      )

      updated_dish = Command::UpdateCommand.call(
        user_id:,
        dish_for_update:,
        dish_source_relation:,
        dish_tags:,
      )
      [updated_dish, created_dish_source]
    end
  end
end
