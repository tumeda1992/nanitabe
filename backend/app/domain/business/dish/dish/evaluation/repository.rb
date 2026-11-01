module Business::Dish::Dish::Evaluation
  class Repository < ::Business::Base::Repository
    class << self
      def find(dish_id)
        dish_evaluation_record = ::DishEvaluation.find_by(dish_id:)
        return if dish_evaluation_record.blank?

        build_values_object_with_existing_object(dish_evaluation_record, Evaluation, [:user_id, :dish_id, :score])
      end

      def add(evaluation)
        new_dish_evaluation_record = set_same_name_fields(evaluation, ::DishEvaluation.new, [:user_id, :dish_id, :score])
        new_dish_evaluation_record.save!
        evaluation
      end

      def update(updated_dish_evaluation, update_user_id, force_update: false)
        existing_dish_evaluation_record = ::DishEvaluation.find_by(dish_id: updated_dish_evaluation.dish_id)

        can_update = ::Dish.where(id: updated_dish_evaluation.dish_id, user_id: update_user_id).exists? || force_update
        raise "このユーザはこのレコードを更新できません。" unless can_update

        dish_evaluation_record_for_update = set_same_name_fields(updated_dish_evaluation, existing_dish_evaluation_record, [:score])
        dish_evaluation_record_for_update.user_id = update_user_id unless force_update
        dish_evaluation_record_for_update.save!
      end
    end
  end
end
