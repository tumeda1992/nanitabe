module Types
  class MutationType < Types::BaseObject
    has_no_fields(true)

    field :add_meal, mutation: ::Mutations::Meal::AddMeal
    field :add_meal_with_new_dish, mutation: ::Mutations::Meal::AddMealWithNewDish
    field :add_meal_with_new_dish_and_new_source, mutation: ::Mutations::Meal::AddMealWithNewDishAndNewSource
    field :update_meal, mutation: ::Mutations::Meal::UpdateMeal
    field :update_meal_with_new_dish, mutation: ::Mutations::Meal::UpdateMealWithNewDish
    field :update_meal_with_new_dish_and_new_source, mutation: ::Mutations::Meal::UpdateMealWithNewDishAndNewSource
    field :remove_meal, mutation: ::Mutations::Meal::RemoveMeal

    field :swap_meals_between_days, mutation: ::Mutations::Meal::SwapMealsBetweenDays

    field :add_dish, mutation: ::Mutations::Dish::AddDish
    field :add_dish_with_new_source, mutation: ::Mutations::Dish::AddDishWithNewSource
    field :update_dish, mutation: ::Mutations::Dish::UpdateDish
    field :update_dish_with_new_source, mutation: ::Mutations::Dish::UpdateDishWithNewSource
    field :remove_dish, mutation: ::Mutations::Dish::RemoveDish

    field :add_dish_source, mutation: ::Mutations::Dish::Source::AddSource
    field :update_dish_source, mutation: ::Mutations::Dish::Source::UpdateSource
    field :remove_dish_source, mutation: ::Mutations::Dish::Source::RemoveSource

    field :evaluate_dish, mutation: ::Mutations::Dish::Evaluation::EvaluateDish

    field :bulk_add_tag_to_dishes, mutation: ::Mutations::Dish::Tag::BulkAddTagToDishes

    field :add_meal_frame, mutation: ::Mutations::Meal::Frame::AddMealFrame
    field :update_meal_frame, mutation: ::Mutations::Meal::Frame::UpdateMealFrame
    field :delete_meal_frame, mutation: ::Mutations::Meal::Frame::DeleteMealFrame

    field :add_meal_frame_entry, mutation: ::Mutations::Meal::FrameEntry::AddMealFrameEntry
    field :remove_meal_frame_entry, mutation: ::Mutations::Meal::FrameEntry::RemoveMealFrameEntry
  end
end
