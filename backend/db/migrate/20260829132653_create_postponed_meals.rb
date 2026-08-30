class CreatePostponedMeals < ActiveRecord::Migration[7.2]
  def change
    create_table :postponed_meals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :dish, null: false, foreign_key: true
      t.integer :meal_type, null: false

      t.timestamps
    end
  end
end
