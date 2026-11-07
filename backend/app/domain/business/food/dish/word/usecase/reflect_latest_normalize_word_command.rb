module Business::Food::Dish::Word
  class Usecase::ReflectLatestNormalizeWordCommand < ::Business::Base::Command
    def call
      ::ActiveRecord::Base.transaction do
        # FIXME: いずれ非同期化

        dish_ids = ::Dish.all.pluck(:id)
        dish_ids.each_with_index do |dish_id, i|
          dish_name = nil
          begin
            dish_root = ::Business::Food::Dish::Factory.build_existing_from_id(dish_id)
            dish_name = dish_root.name.value
            Rails.logger.info("#{log_prefix(i + 1, dish_ids.size, dish_id, dish_name)}の正規化を開始します")

            dish_root.tags.each(&:renormalize_content)

            dish_root.renormalize_name
            ::Dish.persist_from_food_dish_root(dish_root)
            Rails.logger.info("#{log_prefix(i + 1, dish_ids.size, dish_id, dish_name)}の正規化が完了しました")
          rescue StandardError => e
            raise Errors::ReflectLatestNormalizeWordError, "#{log_prefix(i + 1, dish_ids.size, dish_id, dish_name)}の正規化に失敗しました: #{e.message}"
          end
        end
      end
    end

    def log_prefix(index, size, dish_id, dish_name)
      "#{index}/#{size} dish_id: #{dish_id}(#{dish_name})"
    end
  end
end
