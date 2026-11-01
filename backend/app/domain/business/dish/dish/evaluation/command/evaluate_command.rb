module Business::Dish::Dish::Evaluation
  class Command::EvaluateCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true
    attribute :dish_id, :integer
    validates :dish_id, presence: true
    attribute :score, :float
    validates :score, presence: true

    def call
      ::Dish.where(user_id: user_id).find(dish_id)

      existing_evaluation = Repository.find(dish_id)

      if existing_evaluation.blank?
        evaluation = Evaluation.new(
          user_id:,
          dish_id:,
          score:,
        )
        Repository.add(evaluation)
        evaluation
      else
        existing_evaluation.user_id = user_id
        existing_evaluation.score = score
        Repository.update(existing_evaluation, user_id)
        existing_evaluation
      end
    end
  end
end
