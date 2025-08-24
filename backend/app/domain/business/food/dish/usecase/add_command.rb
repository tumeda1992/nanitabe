module Business::Food::Dish
  class Usecase::AddCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_params, :command_params
    validates :dish_params, presence: true
    validate :validate_dish, if: -> { dish_params.present? }

    def call
      dish_root = Business::Food::Dish::Factory.build(
        user_id,
        dish_params.name,
        dish_params.meal_position,
        comment: dish_params.comment
      )
      # TODO: このメソッド廃止予定。
      # 集約ルートはテーブルのためのものではないのに、集約ルートとテーブルを1:1対応させている
      # tagとか含めて全部集約を作りきってから、それをまとめてsaveしにいく
      # 更新を作れば自ずと形が見えてくるから、それに合わせて作成も
      dish_record = ::Dish.build_from_food_dish_root(dish_root)
      dish_record.save!
      dish_root.set_id(dish_record.id)

      # TODO: タグとの関連付け

      # TODO: ソースとの関連付け

      dish_root
    end

    private

    def validate_dish
      return if dish_params.valid_for_create?

      errors.add(:dish_params, dish_params.errors.full_messages.join(', '))
    end
  end
end
