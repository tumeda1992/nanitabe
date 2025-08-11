class Dish < ApplicationRecord
  validates :name, presence: true
  validates :meal_position, presence: true

  belongs_to :user
  has_many :meals

  has_one :dish_source_relation, dependent: :destroy
  has_one :dish_source, through: :dish_source_relation

  has_one :dish_evaluation, dependent: :destroy
  has_many :dish_tags, dependent: :destroy

  class << self
    def build_from_food_dish_root(food_dish_root)
      new(
        id: food_dish_root.id,
        user_id: food_dish_root.user_id,
        name: food_dish_root.name,
        normalized_name: food_dish_root.normalized_name,
        meal_position: food_dish_root.meal_position,
        comment: food_dish_root.comment
      )
    end
  end
end
