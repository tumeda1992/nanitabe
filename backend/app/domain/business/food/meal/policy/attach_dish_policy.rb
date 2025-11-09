module Business::Food::Meal
  class Policy::AttachDishPolicy
    class << self
      def ensure!(dish_id)
        raise "料理が指定されていません。" if dish_id.blank?
        # NOTE: 永続化層に問い合わせに行っているが、これはidの妥当性検証。存在性のチェックを行うことで、意味不明の文字列でなく、コレクションに保存されたvalidなエンティティを参照していることを保証する
        raise "存在しない料理を紐付けることはできません。" unless ::Dish.where(id: dish_id).exists?

        true
      end
    end
  end
end
