module Business::Dish
  class Root < ::Business::Base::Entity
    attribute :id, :integer

    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :name, :string
    validates :name, presence: true

    attribute :normalized_name, :string

    attribute :meal_position, :integer
    validates :meal_position, presence: true

    attribute :comment, :string
  end
end
