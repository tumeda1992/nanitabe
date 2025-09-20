module Business::Food::Dish
  class Usecase::RemoveCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_id, :integer
    validates :dish_id, presence: true

    def call
      dish_record = ::Dish.find_by(id: dish_id, user_id: user_id)
      raise "指定した料理は存在しません。" if dish_record.blank?

      # ユースケースがはっきり定まっていないので、定まるまで安全に倒す
      raise "この料理は登録されている食事があるので削除できません。" if dish_record.meals.present?

      dish_record.destroy!
    end
  end
end
