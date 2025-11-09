module Business::Food::Dish::Source
  class Usecase::Params::Source < ::Business::Base::CommandParams
    attribute :id, :integer
    validates :id, absence: true, on: :create
    validates :id, presence: true, on: :update

    attribute :name, :string
    validates :name, presence: true, on: :create

    attribute :type, :dish_source_type
    validates :type, presence: true, on: :create

    attribute :comment, :string

    def valid_for_create?
      valid?(on: :create)
    end

    def valid_for_update?
      valid?(on: :update)
    end
  end
end
