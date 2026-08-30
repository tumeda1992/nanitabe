module Business::Food::Meal::Postponed
  class Usecase::PostponedMealsFinder < ::Business::Base::Finder
    ListItem = Struct.new(:id, :dish_id, :dish_name, :meal_type, :comment, :created_at, keyword_init: true)

    attribute :user_id, :integer
    validates :user_id, presence: true

    def fetch
      ::PostponedMeal.where(user_id:).includes(:dish).order(created_at: :desc).map do |record|
        ListItem.new(
          id: record.id,
          dish_id: record.dish_id,
          dish_name: record.dish.name,
          meal_type: record.meal_type,
          comment: record.comment,
          created_at: record.created_at,
        )
      end
    end
  end
end
