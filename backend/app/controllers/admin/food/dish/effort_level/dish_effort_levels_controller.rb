module Admin
  module Food
    module Dish
      module EffortLevel
        class DishEffortLevelsController < ApplicationController
          def index
            @dish_effort_levels = DishEffortLevel.order(:meal_position, :minutes)
          end

          def new
            @dish_effort_level = DishEffortLevel.new
          end

          def create
            @dish_effort_level = DishEffortLevel.new(dish_effort_level_params)
            if @dish_effort_level.save
              redirect_to admin_food_dish_effort_level_dish_effort_levels_path, notice: "手間レベルを作成しました"
            else
              render :new, status: :unprocessable_entity
            end
          end

          def edit
            @dish_effort_level = DishEffortLevel.find(params[:id])
          end

          def update
            @dish_effort_level = DishEffortLevel.find(params[:id])
            if @dish_effort_level.update(dish_effort_level_params)
              redirect_to admin_food_dish_effort_level_dish_effort_levels_path, notice: "手間レベルを更新しました"
            else
              render :edit, status: :unprocessable_entity
            end
          end

          def destroy
            @dish_effort_level = DishEffortLevel.find(params[:id])
            @dish_effort_level.destroy
            redirect_to admin_food_dish_effort_level_dish_effort_levels_path, notice: "手間レベルを削除しました"
          end

          private

          def dish_effort_level_params
            params.require(:dish_effort_level).permit(:meal_position, :minutes, :label)
          end
        end
      end
    end
  end
end
