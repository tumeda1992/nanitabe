require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Dish::Usecase::DishSearcher do
  let(:user_record) { find_or_create_user }
  let(:other_user) { FactoryBot.create(:user, id_param: "other_user_for_dish_search") }

  # テスト用の料理データを作成
  let!(:dish1) do
    dish = FactoryBot.create(:dish, user: user_record, name: "チキンカレー", normalized_name: "チキンカレー", meal_position: 1)
    FactoryBot.create(:dish_evaluation, dish: dish, user: user_record, score: 4.5)
    FactoryBot.create(:dish_tag, dish: dish, user: user_record, content: "スパイス")
    FactoryBot.create(:dish_tag, dish: dish, user: user_record, content: "辛い")
    dish
  end

  let!(:dish2) do
    dish = FactoryBot.create(:dish, user: user_record, name: "ハンバーグ", normalized_name: "ハンバーグ", meal_position: 1)
    FactoryBot.create(:dish_evaluation, dish: dish, user: user_record, score: 3.5)
    dish
  end

  let!(:dish3) do
    dish = FactoryBot.create(:dish, user: user_record, name: "野菜カレー", normalized_name: "野菜カレー", meal_position: 2)
    FactoryBot.create(:dish_evaluation, dish: dish, user: user_record, score: 4.0)
    dish
  end

  let!(:dish_with_source) do
    dish = FactoryBot.create(:dish, user: user_record, name: "親子丼", normalized_name: "親子丼", meal_position: 1)
    dish_source = FactoryBot.create(:dish_source, user: user_record, name: "料理本A")
    FactoryBot.create(:dish_source_relation, dish: dish, dish_source: dish_source)
    dish
  end

  # 他のユーザーの料理（表示されるべきでない）
  let!(:other_user_dish) do
    FactoryBot.create(:dish, user: other_user, name: "他人の料理", normalized_name: "他人の料理", meal_position: 1)
  end

  describe "validations" do
    context "when access_user_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(
            search_string: "test",
          )
        }.to raise_error(/条件の値が不正です。/)
      end
    end

    context "when access_user_id is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            access_user_id: nil,
            search_string: "test",
          )
        }.to raise_error(/条件の値が不正です。/)
      end
    end
  end

  describe "#fetch" do
    context "with basic search" do
      it "returns user's dishes only" do
        result = described_class.call(
          access_user_id: user_record.id,
        )

        dish_names = result.map { |dish| dish[:name] }
        expect(dish_names).to include("チキンカレー", "ハンバーグ", "野菜カレー", "親子丼")
        expect(dish_names).not_to include("他人の料理")
      end

      it "does not trigger N+1 queries" do
        # 実行されるクエリ:
        # - メインクエリ
        # - preloadするテーブル用のクエリ
        expect_query_count(5) do
          described_class.call(access_user_id: user_record.id)
        end
      end

      it "includes dish source information" do
        result = described_class.call(
          access_user_id: user_record.id,
        )

        dish_with_source_result = result.find { |dish| dish[:name] == "親子丼" }
        expect(dish_with_source_result[:dish_source_relation]).to be_a(Hash)
        expect(dish_with_source_result[:dish_source_relation][:source_name]).to eq("料理本A")
      end

      it "includes evaluation score" do
        result = described_class.call(
          access_user_id: user_record.id,
        )

        chicken_curry = result.find { |dish| dish[:name] == "チキンカレー" }
        expect(chicken_curry[:evaluation_score]).to eq(4.5)
      end
    end

    context "with search_string" do
      it "searches by dish name" do
        result = described_class.call(
          access_user_id: user_record.id,
          search_string: "カレー",
        )

        dish_names = result.map { |dish| dish[:name] }
        expect(dish_names).to include("チキンカレー", "野菜カレー")
        expect(dish_names).not_to include("ハンバーグ", "親子丼")
      end

      it "searches by dish source name" do
        result = described_class.call(
          access_user_id: user_record.id,
          search_string: "料理本",
        )

        dish_names = result.map { |dish| dish[:name] }
        expect(dish_names).to include("親子丼")
        expect(dish_names).not_to include("チキンカレー", "ハンバーグ")
      end

      it "searches by dish tag content" do
        result = described_class.call(
          access_user_id: user_record.id,
          search_string: "スパイス",
        )

        dish_names = result.map { |dish| dish[:name] }
        expect(dish_names).to include("チキンカレー")
        expect(dish_names).not_to include("ハンバーグ", "野菜カレー")
      end

      it "returns empty result for non-matching search" do
        result = described_class.call(
          access_user_id: user_record.id,
          search_string: "存在しない料理",
        )

        expect(result).to be_empty
      end
    end

    context "with meal_position filter" do
      it "filters by meal_position" do
        result = described_class.call(
          access_user_id: user_record.id,
          meal_position: 1,
        )

        dish_names = result.map { |dish| dish[:name] }
        expect(dish_names).to include("チキンカレー", "ハンバーグ", "親子丼")
        expect(dish_names).not_to include("野菜カレー") # meal_position: 2
      end
    end

    context "with registered_with_meal filter" do
      let!(:meal_for_dish1) do
        FactoryBot.create(:meal, user: user_record, dish: dish1, date: Date.today)
      end

      it "filters dishes registered with meals when registered_with_meal is true" do
        result = described_class.call(
          access_user_id: user_record.id,
          registered_with_meal: true,
        )

        dish_names = result.map { |dish| dish[:name] }
        expect(dish_names).to include("チキンカレー")
        expect(dish_names).not_to include("ハンバーグ", "野菜カレー", "親子丼")
      end

      it "filters dishes not registered with meals when registered_with_meal is false" do
        result = described_class.call(
          access_user_id: user_record.id,
          registered_with_meal: false,
        )

        dish_names = result.map { |dish| dish[:name] }
        expect(dish_names).to include("ハンバーグ", "野菜カレー", "親子丼")
        expect(dish_names).not_to include("チキンカレー")
      end
    end

    context "with dish_id_registered_with_meal" do
      it "includes the specified dish at the beginning of results" do
        result = described_class.call(
          access_user_id: user_record.id,
          dish_id_registered_with_meal: dish2.id,
        )

        expect(result.first[:id]).to eq(dish2.id)
        expect(result.first[:name]).to eq("ハンバーグ")

        # 指定した料理は結果の残りの部分からは除外される
        remaining_dish_ids = result[1..-1].map { |dish| dish[:id] }
        expect(remaining_dish_ids).not_to include(dish2.id)
      end

      it "returns only other dishes when dish_id_registered_with_meal is specified" do
        result = described_class.call(
          access_user_id: user_record.id,
          dish_id_registered_with_meal: dish1.id,
        )

        expect(result.first[:id]).to eq(dish1.id)

        other_dish_names = result[1..-1].map { |dish| dish[:name] }
        expect(other_dish_names).to include("ハンバーグ", "野菜カレー", "親子丼")
        expect(other_dish_names).not_to include("チキンカレー")
      end
    end

    context "with multiple filters combined" do
      it "applies all filters correctly" do
        result = described_class.call(
          access_user_id: user_record.id,
          search_string: "カレー",
          meal_position: 1,
        )

        dish_names = result.map { |dish| dish[:name] }
        expect(dish_names).to include("チキンカレー")
        expect(dish_names).not_to include("野菜カレー") # meal_position: 2
        expect(dish_names).not_to include("ハンバーグ", "親子丼")
      end
    end

    context "ordering" do
      let!(:low_rated_dish) do
        dish = FactoryBot.create(:dish, user: user_record, name: "低評価料理", normalized_name: "低評価料理", meal_position: 1)
        FactoryBot.create(:dish_evaluation, dish: dish, user: user_record, score: 2.0)
        dish
      end

      let!(:no_rating_dish) do
        FactoryBot.create(:dish, user: user_record, name: "未評価料理", normalized_name: "未評価料理", meal_position: 1)
      end

      it "orders by evaluation score descending" do
        result = described_class.call(
          access_user_id: user_record.id,
        )

        # 評価スコアの高い順に並んでいることを確認
        chicken_curry_index = result.find_index { |dish| dish[:name] == "チキンカレー" }
        vegetable_curry_index = result.find_index { |dish| dish[:name] == "野菜カレー" }
        hamburg_index = result.find_index { |dish| dish[:name] == "ハンバーグ" }
        low_rated_index = result.find_index { |dish| dish[:name] == "低評価料理" }

        expect(chicken_curry_index).to be < vegetable_curry_index # 4.5 > 4.0
        expect(vegetable_curry_index).to be < hamburg_index # 4.0 > 3.5
        expect(hamburg_index).to be < low_rated_index # 3.5 > 2.0
      end
    end

    context "response structure" do
      it "includes all required dish fields" do
        result = described_class.call(
          access_user_id: user_record.id,
        )

        dish_result = result.first
        expect(dish_result).not_to be_nil
        expect(dish_result).to be_a(Hash)

        # 基本フィールドの存在確認
        expect(dish_result).to have_key(:id)
        expect(dish_result).to have_key(:name)
        expect(dish_result).to have_key(:normalized_name)
        expect(dish_result).to have_key(:meal_position)
        expect(dish_result).to have_key(:user_id)
        expect(dish_result).to have_key(:comment)
        expect(dish_result).to have_key(:dish_source_relation)
        expect(dish_result).to have_key(:evaluation_score)
        expect(dish_result).to have_key(:tags)

        # 基本フィールドの値チェック
        expect(dish_result[:id]).to be_a(Integer)
        expect(dish_result[:name]).to be_a(String)
        expect(dish_result[:meal_position]).to be_a(Integer)
        expect(dish_result[:user_id]).to eq(user_record.id)
      end

      context "when dish has all optional relations" do
        it "includes related data correctly" do
          result = described_class.call(
            access_user_id: user_record.id,
          )

          dish_with_relations = result.find { |d| d[:name] == "チキンカレー" }
          expect(dish_with_relations).not_to be_nil
          expect(dish_with_relations[:evaluation_score]).to eq(4.5)
          expect(dish_with_relations[:evaluation_score]).to be_a(Float).or(be_a(BigDecimal))
          expect(dish_with_relations[:tags]).to be_an(Array)
          expect(dish_with_relations[:tags].size).to eq(2)
        end
      end

      context "when dish has no optional relations" do
        let!(:minimal_dish) do
          FactoryBot.create(:dish,
            user: user_record,
            name: "シンプルな料理",
            normalized_name: "シンプルな料理",
            meal_position: 1,)
        end

        it "returns nil for missing optional fields" do
          result = described_class.call(
            access_user_id: user_record.id,
          )

          simple_dish = result.find { |d| d[:name] == "シンプルな料理" }
          expect(simple_dish).not_to be_nil
          expect(simple_dish[:dish_source_relation]).to be_nil
          expect(simple_dish[:evaluation_score]).to be_nil
          expect(simple_dish[:tags]).to eq([])
        end
      end
    end
  end
end
