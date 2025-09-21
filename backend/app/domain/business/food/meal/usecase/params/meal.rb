module Business::Food::Meal
  class Usecase::Params::Meal < ::Business::Base::CommandParams
    attribute :id, :integer
    validates :id, absence: true, on: :create
    validates :id, presence: true, on: :update

    attribute :date, :date
    validates :date, presence: true

    attribute :meal_type, :integer
    validates :meal_type, presence: true

    attribute :comment, :string

    def valid_for_create?
      valid?(on: :create)
    end

    def valid_for_update?
      valid?(on: :update)
    end
  end
end
