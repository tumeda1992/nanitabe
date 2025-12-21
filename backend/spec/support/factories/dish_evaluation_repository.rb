require_relative "./dish_sources_repository"

def find_or_create_dish_evaluation
  ::DishEvaluation.find_by(dish_id: find_or_create_dish().id) || FactoryBot.create(:dish_evaluation)
end
