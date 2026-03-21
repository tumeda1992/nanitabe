class CreateMealFrameEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :meal_frame_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :meal_frame, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :meal_type, null: false
      t.references :meal, null: true, foreign_key: true

      t.timestamps
    end
  end
end
