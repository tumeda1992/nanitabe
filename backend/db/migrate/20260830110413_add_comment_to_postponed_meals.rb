class AddCommentToPostponedMeals < ActiveRecord::Migration[7.2]
  def change
    add_column :postponed_meals, :comment, :string, null: true
  end
end
