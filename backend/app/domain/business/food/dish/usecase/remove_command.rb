module Business::Food::Dish
  class Usecase::RemoveCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_id, :integer
    validates :dish_id, presence: true

    def call
      dish_record = ::Dish.find_by(id: dish_id, user_id: user_id)
      raise "指定した料理は存在しません。" if dish_record.blank?

      # TODO: 紐付く食事がある場合削除できないチェック作る

      dish_record.destroy!
    end
  end
end
