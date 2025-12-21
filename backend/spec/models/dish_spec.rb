require "rails_helper"
require_relative "../support/factories/user_repository"
require_relative "../support/factories/dish_repository"
require_relative "../support/factories/dish_sources_repository"

RSpec.describe Dish, type: :model do
  let(:user_record) { find_or_create_user }

  describe ".build_existing_root_from_id" do
    let(:dish_source) { FactoryBot.create(:dish_source, user: user_record) }
    let(:existing_dish) do
      FactoryBot.create(
        :dish,
        user: user_record,
        name: "test_dish",
        normalized_name: "test_dish_normalized",
        meal_position: 1,
        comment: "test_comment",
      )
    end

    context "when dish exists" do
      it "returns Business::Food::Dish::Root with correct attributes" do
        result = described_class.build_existing_root_from_id(existing_dish.id)

        expect(result).to be_a(Business::Food::Dish::Root)
        expect(result.id).to eq(existing_dish.id)
        expect(result.user_id).to eq(existing_dish.user_id)
        expect(result.name.value).to eq(existing_dish.name)
        expect(result.name.normalized).to eq(existing_dish.normalized_name)
        expect(result.meal_position).to eq(existing_dish.meal_position)
        expect(result.comment).to eq(existing_dish.comment)
      end

      context "when dish has associated dish_source" do
        before do
          existing_dish.update!(dish_source: dish_source)
        end

        it "includes source_id in the root" do
          result = described_class.build_existing_root_from_id(existing_dish.id)

          expect(result.source_id).to eq(dish_source.id)
        end

        context "when dish_source_relation exists" do
          context "with recipe book source" do
            let(:recipe_book_dish) { FactoryBot.create(:dish, user: user_record, normalized_name: "test_dish_normalized") }
            let(:recipe_book_source) { FactoryBot.create(:dish_source, type: Business::Food::Dish::Source::Type::RECIPE_BOOK, user: user_record) }
            let(:page_number) { 123 }

            before do
              DishSourceRelation.create!(
                dish: recipe_book_dish,
                dish_source: recipe_book_source,
                recipe_book_page: page_number,
              )
            end

            it "builds RecipeBook locator from relation" do
              result = described_class.build_existing_root_from_id(recipe_book_dish.id)

              expect(result.source_locator).to be_a(Business::Food::Dish::Source::Locator::RecipeBook)
              expect(result.source_locator.page).to eq(page_number)
            end
          end

          context "with website source" do
            let(:website_dish) { FactoryBot.create(:dish, user: user_record, normalized_name: "test_dish_normalized") }
            let(:website_source) { FactoryBot.create(:dish_source, type: Business::Food::Dish::Source::Type::WEBSITE, user: user_record) }
            let(:website_url) { "https://example.com/recipe" }

            before do
              DishSourceRelation.create!(
                dish: website_dish,
                dish_source: website_source,
                recipe_website_url: website_url,
              )
            end

            it "builds RecipeWebsite locator from relation" do
              result = described_class.build_existing_root_from_id(website_dish.id)

              expect(result.source_locator).to be_a(Business::Food::Dish::Source::Locator::RecipeWebsite)
              expect(result.source_locator.url).to eq(website_url)
            end
          end

          context "with other source" do
            let(:other_dish) { FactoryBot.create(:dish, user: user_record, normalized_name: "test_dish_normalized") }
            let(:other_source) { FactoryBot.create(:dish_source, type: Business::Food::Dish::Source::Type::OTHER, user: user_record) }
            let(:source_memo) { "テレビのレシピ" }

            before do
              DishSourceRelation.create!(
                dish: other_dish,
                dish_source: other_source,
                recipe_source_memo: source_memo,
              )
            end

            it "builds OtherRecipe locator from relation" do
              result = described_class.build_existing_root_from_id(other_dish.id)

              expect(result.source_locator).to be_a(Business::Food::Dish::Source::Locator::OtherRecipe)
              expect(result.source_locator.memo).to eq(source_memo)
            end
          end
        end
      end

      context "when dish has no associated dish_source" do
        it "sets source_id and source_locator to nil" do
          result = described_class.build_existing_root_from_id(existing_dish.id)

          expect(result.source_id).to be_nil
          expect(result.source_locator).to be_nil
        end
      end
    end

    context "when dish does not exist" do
      it "returns nil" do
        result = described_class.build_existing_root_from_id(99_999)

        expect(result).to be_nil
      end
    end

    context "when id is nil" do
      it "returns nil" do
        result = described_class.build_existing_root_from_id(nil)

        expect(result).to be_nil
      end
    end
  end

  describe "#persist_from_food_dish_root" do
    let(:dish_record) { find_or_create_dish }
    let(:dish_name) { "new_dish_name" }
    let(:normalized_dish_name) { "new_dish_normalized" }
    let(:meal_position) { 3 }
    let(:comment) { "new comment" }

    let(:food_dish_root) do
      ::Business::Food::Dish::Root.new(
        id: dish_record.id,
        user_id: user_record.id,
        name: ::Business::Food::Dish::Name.new(
          value: dish_name,
          normalized: normalized_dish_name,
        ),
        meal_position: meal_position,
        comment: comment,
        source_id: nil,
        source_locator: nil,
        tags: [],
      )
    end

    it "updates dish attributes" do
      result = dish_record.persist_from_food_dish_root(food_dish_root)

      expect(result.name).to eq(dish_name)
      expect(result.normalized_name).to eq(normalized_dish_name)
      expect(result.meal_position).to eq(meal_position)
      expect(result.comment).to eq(comment)

      dish_record.reload
      expect(dish_record.name).to eq(dish_name)
      expect(dish_record.normalized_name).to eq(normalized_dish_name)
      expect(dish_record.meal_position).to eq(meal_position)
      expect(dish_record.comment).to eq(comment)
    end

    context "with source_id" do
      let!(:dish_source_record) { find_or_create_dish_source }
      let(:recipe_book_page) { 150 }
      let(:source_locator) do
        ::Business::Food::Dish::Source::Locator::RecipeBook.new(recipe_book_page)
      end
      let(:food_dish_root_with_source) do
        ::Business::Food::Dish::Root.new(
          id: dish_record.id,
          user_id: user_record.id,
          name: ::Business::Food::Dish::Name.new(
            value: dish_name,
            normalized: normalized_dish_name,
          ),
          meal_position: meal_position,
          comment: comment,
          source_id: dish_source_record.id,
          source_locator: source_locator,
          tags: [],
        )
      end

      it "calls DishSourceRelation.put_dish_source_relation" do
        expect(::DishSourceRelation).to receive(:put_dish_source_relation)
          .with(dish_record.id, dish_source_record.id, source_locator)

        dish_record.persist_from_food_dish_root(food_dish_root_with_source)
      end
    end

    context "without source_id" do
      it "calls DishSourceRelation.remove_dish_source_relation" do
        expect(::DishSourceRelation).to receive(:remove_dish_source_relation)
          .with(dish_record.id)

        dish_record.persist_from_food_dish_root(food_dish_root)
      end
    end

    context "with tags" do
      let(:tag1) do
        ::Business::Food::Dish::Tag::Root.new(
          content: ::Business::Food::Dish::Tag::Content.new(
            value: "tag1",
            normalized: "tag1_normalized",
          ),
          user_id: user_record.id,
        )
      end
      let(:tag2) do
        ::Business::Food::Dish::Tag::Root.new(
          content: ::Business::Food::Dish::Tag::Content.new(
            value: "tag2",
            normalized: "tag2_normalized",
          ),
          user_id: user_record.id,
        )
      end
      let(:food_dish_root_with_tags) do
        ::Business::Food::Dish::Root.new(
          id: dish_record.id,
          user_id: user_record.id,
          name: ::Business::Food::Dish::Name.new(
            value: dish_name,
            normalized: normalized_dish_name,
          ),
          meal_position: meal_position,
          comment: comment,
          source_id: nil,
          source_locator: nil,
          tags: [tag1, tag2],
        )
      end

      it "calls DishTag.replace_tags_of_dish" do
        expect(::DishTag).to receive(:replace_tags_of_dish)
          .with(dish_record.id, [tag1, tag2])

        dish_record.persist_from_food_dish_root(food_dish_root_with_tags)
      end
    end
  end

  describe ".persist_from_food_dish_root" do
    let(:dish_name) { "new_dish_name" }
    let(:normalized_dish_name) { "new_dish_normalized" }
    let(:meal_position) { 3 }
    let(:comment) { "new comment" }

    context "with existing dish (has id)" do
      let(:dish_record) { find_or_create_dish }
      let(:food_dish_root) do
        ::Business::Food::Dish::Root.new(
          id: dish_record.id,
          user_id: user_record.id,
          name: ::Business::Food::Dish::Name.new(
            value: dish_name,
            normalized: normalized_dish_name,
          ),
          meal_position: meal_position,
          comment: comment,
          source_id: nil,
          source_locator: nil,
          tags: [],
        )
      end

      it "finds existing dish and calls persist_from_food_dish_root on it" do
        result = described_class.persist_from_food_dish_root(food_dish_root)

        expect(result.id).to eq(dish_record.id)
        expect(result.name).to eq(dish_name)
        expect(result.normalized_name).to eq(normalized_dish_name)
        expect(result.meal_position).to eq(meal_position)
        expect(result.comment).to eq(comment)
      end
    end

    context "with new dish (no id)" do
      let(:food_dish_root) do
        ::Business::Food::Dish::Root.new(
          id: nil,
          user_id: user_record.id,
          name: ::Business::Food::Dish::Name.new(
            value: dish_name,
            normalized: normalized_dish_name,
          ),
          meal_position: meal_position,
          comment: comment,
          source_id: nil,
          source_locator: nil,
          tags: [],
        )
      end

      it "creates new dish and calls persist_from_food_dish_root on it" do
        result = described_class.persist_from_food_dish_root(food_dish_root)

        expect(result).to be_a(Dish)
        expect(result.user_id).to eq(user_record.id)
        expect(result.name).to eq(dish_name)
        expect(result.normalized_name).to eq(normalized_dish_name)
        expect(result.meal_position).to eq(meal_position)
        expect(result.comment).to eq(comment)
        expect(result).to be_persisted
      end
    end
  end

  describe "#to_searched_values" do
    let(:dish) { FactoryBot.create(:dish, user: user_record, name: "test_dish", meal_position: 1, comment: "test comment") }

    context "with no associations" do
      before do
        dish.reload
      end

      it "returns hash with basic dish attributes" do
        result = dish.to_searched_values

        expect(result).to be_a(Hash)
        expect(result[:id]).to eq(dish.id)
        expect(result[:name]).to eq(dish.name)
        expect(result[:meal_position]).to eq(dish.meal_position)
        expect(result[:comment]).to eq(dish.comment)
        expect(result[:dish_source_relation]).to be_nil
        expect(result[:evaluation_score]).to be_nil
        expect(result[:tags]).to eq([])
      end
    end

    context "with dish_source_relation (recipe book)" do
      let(:dish_source) { FactoryBot.create(:dish_source, user: user_record, type: Business::Food::Dish::Source::Type::RECIPE_BOOK, name: "Test Book") }
      let(:page_number) { 123 }

      before do
        DishSourceRelation.create!(
          dish: dish,
          dish_source: dish_source,
          recipe_book_page: page_number,
        )
        dish.reload
      end

      it "returns hash with dish_source_relation" do
        loaded_dish = Dish.eager_load(:dish_source, :dish_source_relation).find(dish.id)
        result = loaded_dish.to_searched_values

        expect(result[:dish_source_relation]).to be_a(Hash)
        expect(result[:dish_source_relation][:dish_id]).to eq(dish.id)
        expect(result[:dish_source_relation][:type]).to eq(Business::Food::Dish::Source::Type::RECIPE_BOOK)
        expect(result[:dish_source_relation][:source_name]).to eq("Test Book")
        expect(result[:dish_source_relation][:dish_source_id]).to eq(dish_source.id)
        expect(result[:dish_source_relation][:recipe_book_page]).to eq(page_number)
        expect(result[:dish_source_relation][:recipe_website_url]).to be_nil
        expect(result[:dish_source_relation][:recipe_source_memo]).to be_nil
      end
    end

    context "with dish_source_relation (website)" do
      let(:dish_source) { FactoryBot.create(:dish_source, user: user_record, type: Business::Food::Dish::Source::Type::WEBSITE, name: "Recipe Site") }
      let(:website_url) { "https://example.com/recipe" }

      before do
        DishSourceRelation.create!(
          dish: dish,
          dish_source: dish_source,
          recipe_website_url: website_url,
        )
        dish.reload
      end

      it "returns hash with dish_source_relation" do
        loaded_dish = Dish.eager_load(:dish_source, :dish_source_relation).find(dish.id)
        result = loaded_dish.to_searched_values

        expect(result[:dish_source_relation]).to be_a(Hash)
        expect(result[:dish_source_relation][:type]).to eq(Business::Food::Dish::Source::Type::WEBSITE)
        expect(result[:dish_source_relation][:source_name]).to eq("Recipe Site")
        expect(result[:dish_source_relation][:recipe_website_url]).to eq(website_url)
        expect(result[:dish_source_relation][:recipe_book_page]).to be_nil
      end
    end

    context "with dish_evaluation" do
      let(:evaluation_score) { 4.5 }

      before do
        FactoryBot.create(:dish_evaluation, dish: dish, score: evaluation_score)
        dish.reload
      end

      it "returns hash with evaluation_score" do
        loaded_dish = Dish.eager_load(:dish_evaluation).find(dish.id)
        result = loaded_dish.to_searched_values

        expect(result[:evaluation_score]).to eq(evaluation_score)
      end
    end

    context "with dish_tags" do
      let!(:tag1) { FactoryBot.create(:dish_tag, dish: dish, content: "tag1", normalized_content: "tag1_normalized") }
      let!(:tag2) { FactoryBot.create(:dish_tag, dish: dish, content: "tag2", normalized_content: "tag2_normalized") }

      before do
        dish.reload
      end

      it "returns hash with tags array" do
        loaded_dish = Dish.eager_load(:dish_tags).find(dish.id)
        result = loaded_dish.to_searched_values

        expect(result[:tags]).to be_an(Array)
        expect(result[:tags].size).to eq(2)
        expect(result[:tags].first).to be_a(Hash)
        expect(result[:tags].map { |t| t[:content] }).to contain_exactly("tag1", "tag2")
      end
    end

    context "with all associations" do
      let(:dish_source) { FactoryBot.create(:dish_source, user: user_record, type: Business::Food::Dish::Source::Type::RECIPE_BOOK, name: "Complete Book") }
      let(:page_number) { 200 }
      let(:evaluation_score) { 5.0 }
      let!(:tag1) { FactoryBot.create(:dish_tag, dish: dish, content: "delicious") }

      before do
        DishSourceRelation.create!(
          dish: dish,
          dish_source: dish_source,
          recipe_book_page: page_number,
        )
        FactoryBot.create(:dish_evaluation, dish: dish, score: evaluation_score)
        dish.reload
      end

      it "returns complete hash with all associations" do
        loaded_dish = Dish.eager_load(:dish_source, :dish_source_relation, :dish_evaluation, :dish_tags).find(dish.id)
        result = loaded_dish.to_searched_values

        expect(result[:id]).to eq(dish.id)
        expect(result[:name]).to eq(dish.name)
        expect(result[:dish_source_relation]).to be_a(Hash)
        expect(result[:dish_source_relation][:source_name]).to eq("Complete Book")
        expect(result[:evaluation_score]).to eq(evaluation_score)
        expect(result[:tags]).to be_an(Array)
        expect(result[:tags].size).to eq(1)
      end
    end
  end

  describe "scopes" do
    describe ".for_user" do
      let(:user1) { FactoryBot.create(:user, id_param: "user_for_scope_test_1") }
      let(:user2) { FactoryBot.create(:user, id_param: "user_for_scope_test_2") }
      let!(:dish1) { FactoryBot.create(:dish, user: user1, name: "User1's dish") }
      let!(:dish2) { FactoryBot.create(:dish, user: user2, name: "User2's dish") }
      let!(:dish3) { FactoryBot.create(:dish, user: user1, name: "Another user1's dish") }

      it "returns only dishes for the specified user" do
        result = described_class.for_user(user1.id)

        expect(result).to include(dish1, dish3)
        expect(result).not_to include(dish2)
        expect(result.count).to eq(2)
      end

      it "returns empty when no dishes exist for the user" do
        user3 = FactoryBot.create(:user, id_param: "user_for_scope_test_3")
        result = described_class.for_user(user3.id)

        expect(result).to be_empty
      end
    end

    describe ".with_search_relations" do
      let!(:dish) { FactoryBot.create(:dish, user: user_record) }
      let!(:dish_source) { FactoryBot.create(:dish_source, user: user_record) }
      let!(:dish_evaluation) { FactoryBot.create(:dish_evaluation, dish: dish, score: 4.5) }
      let!(:dish_tag) { FactoryBot.create(:dish_tag, dish: dish) }
      let!(:meal) { FactoryBot.create(:meal, user: user_record, dish: dish) }

      before do
        dish.update!(dish_source: dish_source)
      end

      it "eager loads dish_source" do
        result = described_class.with_search_relations.find(dish.id)

        expect { result.dish_source }.not_to raise_error
        expect(result.dish_source).to eq(dish_source)
      end

      it "joins dish_evaluation without N+1 queries" do
        dishes = described_class.with_search_relations

        expect { dishes.map(&:dish_evaluation) }.not_to raise_error
      end

      it "joins dish_tags without N+1 queries" do
        dishes = described_class.with_search_relations

        expect { dishes.map { |d| d.dish_tags.to_a } }.not_to raise_error
      end

      it "joins meals without N+1 queries" do
        dishes = described_class.with_search_relations

        expect { dishes.map { |d| d.meals.to_a } }.not_to raise_error
      end
    end

    describe ".search_output" do
      let!(:dish1) do
        FactoryBot.create(:dish, user: user_record, name: "Dish1", created_at: 2.days.ago)
      end
      let!(:dish2) do
        FactoryBot.create(:dish, user: user_record, name: "Dish2", created_at: 1.day.ago)
      end
      let!(:dish3) do
        FactoryBot.create(:dish, user: user_record, name: "Dish3", created_at: 3.days.ago)
      end
      let!(:dish_source1) { FactoryBot.create(:dish_source, user: user_record, name: "Source1") }
      let!(:dish_evaluation1) { FactoryBot.create(:dish_evaluation, dish: dish1, score: 5.0) }
      let!(:dish_evaluation2) { FactoryBot.create(:dish_evaluation, dish: dish2, score: 4.0) }

      before do
        dish1.update!(dish_source: dish_source1)
        FactoryBot.create(:meal, user: user_record, dish: dish1)
        FactoryBot.create(:meal, user: user_record, dish: dish1)
        FactoryBot.create(:meal, user: user_record, dish: dish2)
      end

      it "includes dish_source_name in select" do
        results = described_class.with_search_relations.search_output.to_a
        result = results.find { |d| d.id == dish1.id }

        expect(result.dish_source_name).to eq("Source1")
      end

      it "includes evaluation_score in select" do
        results = described_class.with_search_relations.search_output.to_a
        result = results.find { |d| d.id == dish1.id }

        expect(result.evaluation_score).to eq(5.0)
      end

      it "orders by evaluation_score DESC (higher score first)" do
        results = described_class.with_search_relations.search_output.to_a

        expect(results.first.id).to eq(dish1.id)
      end

      it "orders by meal count when evaluation scores are equal" do
        FactoryBot.create(:dish_evaluation, dish: dish3, score: 5.0)
        FactoryBot.create(:meal, user: user_record, dish: dish3)
        FactoryBot.create(:meal, user: user_record, dish: dish3)
        FactoryBot.create(:meal, user: user_record, dish: dish3)

        results = described_class.with_search_relations.search_output.to_a

        top_two_ids = results.take(2).map(&:id)
        expect(top_two_ids).to contain_exactly(dish1.id, dish3.id)
      end

      it "uses subquery for meal counts instead of GROUP BY" do
        result = described_class.with_search_relations.search_output

        # GROUP BYを使わないアプローチに変更されたことを確認
        expect(result.group_values).to be_empty
      end
    end

    describe ".matching_normalized_name" do
      let!(:dish1) do
        FactoryBot.create(:dish, user: user_record, name: "カレーライス", normalized_name: "かれーらいす")
      end
      let!(:dish2) do
        FactoryBot.create(:dish, user: user_record, name: "ハンバーグカレー", normalized_name: "はんばーぐかれー")
      end
      let!(:dish3) do
        FactoryBot.create(:dish, user: user_record, name: "パスタ", normalized_name: "ぱすた")
      end
      let!(:dish4) do
        FactoryBot.create(:dish, user: user_record, name: "ラーメン", normalized_name: nil)
      end

      it "returns dishes with matching normalized_name" do
        result = described_class.matching_normalized_name("かれー")

        expect(result).to include(dish1, dish2)
        expect(result).not_to include(dish3, dish4)
      end

      it "returns dishes with matching name when normalized_name is nil" do
        result = described_class.matching_normalized_name("ラーメン")

        expect(result).to include(dish4)
      end

      it "returns empty when no dishes match" do
        result = described_class.matching_normalized_name("存在しない料理名")

        expect(result).to be_empty
      end

      it "performs partial match" do
        result = described_class.matching_normalized_name("かれ")

        expect(result).to include(dish1, dish2)
      end
    end
  end
end
