module Business::Dish::Dish
  class Command::CreateWithNewSourceCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_for_create, :command_params
    validates :dish_for_create, presence: true

    attribute :dish_source_for_create, :command_params
    validates :dish_source_for_create, presence: true

    attribute :dish_source_relation_detail, :command_params
    validates :dish_source_relation_detail, presence: false

    attribute :dish_tags, :command_params_array
    validates :dish_tags, presence: false

    def call
      created_dish_source = Source::Command::AddCommand.call(
        user_id:,
        dish_source_for_create:,
      )

      created_dish = Command::AddCommand.call(
        user_id:,
        dish_for_create:,
        dish_source_for_read: Source::Command::Params::SourceForRead.new(
          id: created_dish_source.id,
          **dish_source_for_create.attributes,
        ),
        dish_source_relation_detail:,
        dish_tags:,
      )
      [created_dish, created_dish_source]
    end
  end
end
