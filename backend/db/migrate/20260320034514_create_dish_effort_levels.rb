class CreateDishEffortLevels < ActiveRecord::Migration[7.2]
  def change
    create_table :dish_effort_levels do |t|
      t.integer :meal_position, null: false
      t.integer :minutes, null: false
      t.string :label, null: false

      t.timestamps
    end
    add_index :dish_effort_levels, :meal_position
  end
end
