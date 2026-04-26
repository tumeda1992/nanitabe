class CreateMealFramePatternEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :meal_frame_pattern_entries do |t|
      t.references :meal_frame_pattern, null: false, foreign_key: { on_delete: :cascade }
      t.references :meal_frame, null: false, foreign_key: true
      t.integer :day_offset, null: false
      t.integer :meal_type, null: false
      t.timestamps
    end
  end
end
