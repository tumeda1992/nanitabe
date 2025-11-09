require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Dish::Word::Usecase::ReflectLatestNormalizeWordCommand do
  let(:user_record) { find_or_create_user }

  describe "#call" do
    before do
      # これやらないと、なぜか他のテストで作成されたDishでエラーになるのでクリア
      Dish.delete_all
    end

    context "when dishes exist" do
      let!(:dish1) do
        Dish.create!(
          user: user_record,
          name: "ひらがな",
          normalized_name: "OLD_VALUE_1",
          meal_position: 1
        )
      end

      let!(:dish2) do
        Dish.create!(
          user: user_record,
          name: "test",
          normalized_name: "OLD_VALUE_2",
          meal_position: 1
        )
      end

      it "re-normalizes all dishes" do
        described_class.call

        dish1.reload
        dish2.reload

        # 正規化が実行されたことを確認（古い値ではなくなっている）
        expect(dish1.normalized_name).not_to eq("OLD_VALUE_1")
        expect(dish2.normalized_name).not_to eq("OLD_VALUE_2")

        # 基本的な正規化が適用されている（ひらがな→カタカナ）
        expect(dish1.normalized_name).to eq("ヒラガナ")
      end

      context "when dish has tags" do
        let!(:dish_with_tags) do
          dish = Dish.create!(
            user: user_record,
            name: "タグ付き料理",
            normalized_name: "タグ付き料理",
            meal_position: 1
          )
          # タグを直接DBに挿入（古い正規化値で）
          DishTag.create!(
            user: user_record,
            dish: dish,
            content: "ひらがなたぐ",
            normalized_content: "OLD_TAG_VALUE"
          )
          dish
        end

        it "re-normalizes dish tags content" do
          described_class.call

          tags = DishTag.where(dish_id: dish_with_tags.id)
          expect(tags.count).to eq(1)

          tag = tags.first
          # 正規化が実行されたことを確認
          expect(tag.normalized_content).not_to eq("OLD_TAG_VALUE")
          # 基本的な正規化が適用されている
          expect(tag.normalized_content).to eq("ヒラガナタグ")
          # 元の値は保持される
          expect(tag.content).to eq("ひらがなたぐ")
        end
      end

      it "preserves the original name" do
        described_class.call

        dish1.reload
        dish2.reload

        expect(dish1.name).to eq("ひらがな")
        expect(dish2.name).to eq("test")
      end

      it "processes all dishes in the database" do
        described_class.call

        # 全てのdishが処理されたことを確認
        all_dishes = Dish.where(id: [dish1.id, dish2.id])
        normalized_names = all_dishes.pluck(:normalized_name)

        # 古い値が残っていないことを確認
        expect(normalized_names).not_to include("OLD_VALUE_1", "OLD_VALUE_2")
      end
    end

    context "when no dishes exist" do
      it "completes without error" do
        expect {
          described_class.call
        }.not_to raise_error
      end
    end

    context "with dishes from multiple users" do
      let(:other_user) { FactoryBot.create(:user, id_param: "other_user_for_normalize") }

      let!(:user1_dish) do
        Dish.create!(
          user: user_record,
          name: "ひらがな",
          normalized_name: "OLD_USER1",
          meal_position: 1
        )
      end

      let!(:user2_dish) do
        Dish.create!(
          user: other_user,
          name: "かたかな",
          normalized_name: "OLD_USER2",
          meal_position: 1
        )
      end

      it "updates dishes for all users" do
        described_class.call

        user1_dish.reload
        user2_dish.reload

        # 両ユーザーのdishが更新されている
        expect(user1_dish.normalized_name).not_to eq("OLD_USER1")
        expect(user2_dish.normalized_name).not_to eq("OLD_USER2")
      end
    end

    context "performance" do
      let!(:dishes) do
        5.times.map do |i|
          Dish.create!(
            user: user_record,
            name: "料理#{i}",
            normalized_name: "OLD_#{i}",
            meal_position: 1
          )
        end
      end

      it "processes multiple dishes efficiently" do
        queries = count_queries do
          described_class.call
        end

        # 5つのdishを処理するために必要なクエリ数
        # - 全dish_idの取得: 1
        # - 各dishの処理: 5回 × (取得 + 更新など) = 約10クエリ/dish
        # 過度なN+1がなければ60クエリ以下に収まるはず
        expect(queries.size).to be < 60
      end
    end
  end
end
