class DishEvaluation < ApplicationRecord
  self.primary_key = :dish_id
  belongs_to :user
  belongs_to :dish
end
