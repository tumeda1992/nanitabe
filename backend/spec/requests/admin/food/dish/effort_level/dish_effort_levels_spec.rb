require "rails_helper"

RSpec.describe "Admin::Food::Dish::EffortLevel::DishEffortLevels", type: :request do
  describe "GET /admin/food/dish/effort_level/dish_effort_levels" do
    it "returns http success" do
      get admin_food_dish_effort_level_dish_effort_levels_path
      expect(response).to have_http_status(:success)
    end

    it "displays all DishEffortLevel records" do
      DishEffortLevel.create!(meal_position: 1, minutes: 10, label: "ぱぱっとできる")
      DishEffortLevel.create!(meal_position: 2, minutes: 20, label: "普通")

      get admin_food_dish_effort_level_dish_effort_levels_path

      expect(response.body).to include("ぱぱっとできる")
      expect(response.body).to include("普通")
    end
  end

  describe "GET /admin/food/dish/effort_level/dish_effort_levels/new" do
    it "returns http success" do
      get new_admin_food_dish_effort_level_dish_effort_level_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/food/dish/effort_level/dish_effort_levels" do
    context "正常系" do
      it "creates a new DishEffortLevel and redirects to index" do
        expect do
          post admin_food_dish_effort_level_dish_effort_levels_path,
               params: { dish_effort_level: { meal_position: 1, minutes: 10, label: "ぱぱっとできる" } }
        end.to change(DishEffortLevel, :count).by(1)

        expect(response).to redirect_to(admin_food_dish_effort_level_dish_effort_levels_path)
        follow_redirect!
        expect(response.body).to include("手間レベルを作成しました")
      end
    end

    context "異常系" do
      it "renders new template on validation error" do
        post admin_food_dish_effort_level_dish_effort_levels_path,
             params: { dish_effort_level: { meal_position: nil, minutes: nil, label: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("新規作成")
      end
    end
  end

  describe "GET /admin/food/dish/effort_level/dish_effort_levels/:id/edit" do
    it "returns http success" do
      effort_level = DishEffortLevel.create!(meal_position: 1, minutes: 10, label: "ぱぱっとできる")
      get edit_admin_food_dish_effort_level_dish_effort_level_path(effort_level)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/food/dish/effort_level/dish_effort_levels/:id" do
    let(:effort_level) { DishEffortLevel.create!(meal_position: 1, minutes: 10, label: "ぱぱっとできる") }

    context "正常系" do
      it "updates the DishEffortLevel and redirects to index" do
        patch admin_food_dish_effort_level_dish_effort_level_path(effort_level),
              params: { dish_effort_level: { meal_position: 1, minutes: 20, label: "普通" } }

        expect(response).to redirect_to(admin_food_dish_effort_level_dish_effort_levels_path)
        follow_redirect!
        expect(response.body).to include("手間レベルを更新しました")
      end
    end

    context "異常系" do
      it "renders edit template on validation error" do
        patch admin_food_dish_effort_level_dish_effort_level_path(effort_level),
              params: { dish_effort_level: { meal_position: nil, minutes: nil, label: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("編集")
      end
    end
  end

  describe "DELETE /admin/food/dish/effort_level/dish_effort_levels/:id" do
    it "deletes the DishEffortLevel and redirects to index" do
      effort_level = DishEffortLevel.create!(meal_position: 1, minutes: 10, label: "ぱぱっとできる")

      expect do
        delete admin_food_dish_effort_level_dish_effort_level_path(effort_level)
      end.to change(DishEffortLevel, :count).by(-1)

      expect(response).to redirect_to(admin_food_dish_effort_level_dish_effort_levels_path)
      follow_redirect!
      expect(response.body).to include("手間レベルを削除しました")
    end
  end
end
