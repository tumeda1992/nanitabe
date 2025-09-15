module Business::Food::Dish
  class Usecase::AddWithNewSourceCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_params, :command_params
    validates :dish_params, presence: true

    attribute :source_params, :command_params
    validates :source_params, presence: true

    attribute :dish_source_relation, :command_params
    validates :dish_source_relation, presence: true

    def call
      created_source = Business::Food::Dish::Source::Usecase::AddCommand.call(
        user_id:,
        source_params:
      )
      created_dish = Usecase::AddCommand.call(
        user_id:,
        dish_params:,
        dish_source_relation: dish_source_relation.with_source_id(created_source.id)
      )
      [created_dish, created_source]
    end
  end
end
