class EnsureOneFramePerMeal < ActiveRecord::Migration[7.2]
  def up
    duplicate = connection.select_value(<<~SQL)
      SELECT meal_id FROM meal_frame_entries
      WHERE meal_id IS NOT NULL
      GROUP BY meal_id HAVING COUNT(*) > 1
      LIMIT 1
    SQL
    if duplicate
      raise ActiveRecord::MigrationError, "複数枠に割り当てられた食事があります。割当を確認・整理してから再実行してください。"
    end

    add_index :meal_frame_entries, :meal_id, unique: true, name: "unique_meal_frame_entries_on_meal_id"
    remove_index :meal_frame_entries, name: "index_meal_frame_entries_on_meal_id"
  end

  def down
    add_index :meal_frame_entries, :meal_id, name: "index_meal_frame_entries_on_meal_id"
    remove_index :meal_frame_entries, name: "unique_meal_frame_entries_on_meal_id"
  end
end
