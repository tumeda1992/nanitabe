require "rails_helper"
require_relative "../support/factories/user_repository"

RSpec.describe Dish, type: :model do
  describe ".build_existing_root_from_id" do
    let(:user_record) { find_or_create_user }
    let(:dish_source) { FactoryBot.create(:dish_source, user: user_record) }
    let(:existing_dish) do
      FactoryBot.create(
        :dish,
        user: user_record,
        name: "test_dish",
        normalized_name: "test_dish_normalized",
        meal_position: 1,
        comment: "test_comment"
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
                recipe_book_page: page_number
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
                recipe_website_url: website_url
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
                recipe_source_memo: source_memo
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
        result = described_class.build_existing_root_from_id(99999)

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
end
