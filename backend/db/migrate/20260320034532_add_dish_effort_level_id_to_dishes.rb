class AddDishEffortLevelIdToDishes < ActiveRecord::Migration[7.2]
  def change
    # 型不一致で失敗した integer カラムが残っている場合は削除してから追加
    if column_exists?(:dishes, :dish_effort_level_id)
      remove_column :dishes, :dish_effort_level_id
    end
    add_column :dishes, :dish_effort_level_id, :bigint
    add_foreign_key :dishes, :dish_effort_levels
  end
end
