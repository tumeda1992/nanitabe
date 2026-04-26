class CreateMealFramePatterns < ActiveRecord::Migration[7.2]
  def change
    create_table :meal_frame_patterns do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
  end
end
