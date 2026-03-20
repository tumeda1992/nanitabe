class DishEffortLevel < ApplicationRecord
  validates :meal_position, presence: true
  validates :minutes, presence: true
  validates :label, presence: true

  scope :for_meal_position, ->(meal_position) { where(meal_position:).order(:minutes) }
end
