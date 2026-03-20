# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# dish_effort_levels シードデータ
# meal_position: 1=主食, 2=メインディッシュ, 3=副菜

DISH_EFFORT_LEVEL_SEEDS = [
  # 主食 (1)
  { meal_position: 1, minutes: 10,  label: "ぱぱっとできる" },
  { meal_position: 1, minutes: 20,  label: "普通" },
  { meal_position: 1, minutes: 50,  label: "少し手間" },
  { meal_position: 1, minutes: 150, label: "結構手間" },
  { meal_position: 1, minutes: 480, label: "かなり手間" },
  # メインディッシュ (2)
  { meal_position: 2, minutes: 10,  label: "ぱぱっとできる" },
  { meal_position: 2, minutes: 20,  label: "普通" },
  { meal_position: 2, minutes: 50,  label: "少し手間" },
  { meal_position: 2, minutes: 150, label: "結構手間" },
  { meal_position: 2, minutes: 480, label: "かなり手間" },
  # 副菜 (3)
  { meal_position: 3, minutes: 5,   label: "ぱぱっとできる" },
  { meal_position: 3, minutes: 10,  label: "普通" },
  { meal_position: 3, minutes: 30,  label: "少し手間" },
  { meal_position: 3, minutes: 60,  label: "結構手間" },
].freeze

DISH_EFFORT_LEVEL_SEEDS.each do |seed|
  DishEffortLevel.find_or_create_by!(
    meal_position: seed[:meal_position],
    minutes: seed[:minutes],
  ) do |record|
    record.label = seed[:label]
  end
end

puts "DishEffortLevel: #{DishEffortLevel.count} records seeded."
