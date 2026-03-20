module Business::Food::Dish
  class Usecase::Params::Dish < ::Business::Base::CommandParams
    attribute :id, :integer
    validates :id, absence: true, on: :create
    validates :id, presence: true, on: :update

    attribute :name, :string
    validates :name, presence: true, on: :create

    attribute :meal_position, :integer
    validates :meal_position, presence: true, on: :create

    attribute :comment, :string

    attribute :effort_level_id, :integer

    def valid_for_create?
      valid?(on: :create)
    end

    def valid_for_update?
      valid?(on: :update)
    end
  end
end
