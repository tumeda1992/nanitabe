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

      # 延期された食事は単体で削除する操作を持たないため、このガードに掛かった料理は
      # 「日付を与えて確定 → その食事を削除」という迂回でしか消せない。
      # 料理の削除が稀な操作であるため、迂回を許容してガード側を優先している。
      raise "この料理は延期された食事があるので削除できません。" if dish_record.postponed_meals.present?

      dish_record.destroy!
    end
  end
end
