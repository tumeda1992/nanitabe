require "rails_helper"
require_relative "../support/factories/user_repository"
require_relative "../support/factories/dish_repository"
require_relative "../support/factories/dish_sources_repository"

RSpec.describe DishSourceRelation, type: :model do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }

  describe ".remove_dish_source_relation" do
    context "when dish source relation exists" do
      let!(:dish_source_record) { find_or_create_dish_source }
      let!(:dish_source_relation) do
        FactoryBot.create(
          :dish_source_relation,
          dish: dish_record,
          dish_source: dish_source_record,
          recipe_book_page: 100,
        )
      end

      it "removes the dish source relation" do
        expect {
          described_class.remove_dish_source_relation(dish_record.id)
        }.to change { DishSourceRelation.count }.by(-1)

        expect(DishSourceRelation.find_by(dish_id: dish_record.id)).to be_nil
      end
    end

    context "when dish source relation does not exist" do
      it "does not raise an error" do
        expect {
          described_class.remove_dish_source_relation(dish_record.id)
        }.not_to raise_error
      end

      it "does not change the relation count" do
        expect {
          described_class.remove_dish_source_relation(dish_record.id)
        }.not_to change { DishSourceRelation.count }
      end
    end
  end

  describe ".put_dish_source_relation" do
    let!(:dish_source_record) { find_or_create_dish_source }

    context "when no existing relation" do
      context "with recipe book source" do
        let(:recipe_book_page) { 123 }
        let(:recipe_locator) do
          ::Business::Food::Dish::Source::Locator::RecipeBook.new(recipe_book_page)
        end

        it "creates new dish source relation" do
          expect {
            described_class.put_dish_source_relation(dish_record.id, dish_source_record.id, recipe_locator)
          }.to change { DishSourceRelation.count }.by(1)

          relation = DishSourceRelation.find_by(dish_id: dish_record.id)
          expect(relation.dish_source_id).to eq(dish_source_record.id)
          expect(relation.recipe_book_page).to eq(recipe_book_page)
          expect(relation.recipe_website_url).to be_nil
          expect(relation.recipe_source_memo).to be_nil
        end
      end

      context "with youtube source" do
        let!(:youtube_source_record) { find_or_create_dish_source_of_youtube }
        let(:recipe_website_url) { "https://youtube.com/recipe" }
        let(:recipe_locator) do
          ::Business::Food::Dish::Source::Locator::RecipeWebsite.new(recipe_website_url)
        end

        it "creates new dish source relation" do
          expect {
            described_class.put_dish_source_relation(dish_record.id, youtube_source_record.id, recipe_locator)
          }.to change { DishSourceRelation.count }.by(1)

          relation = DishSourceRelation.find_by(dish_id: dish_record.id)
          expect(relation.dish_source_id).to eq(youtube_source_record.id)
          expect(relation.recipe_book_page).to be_nil
          expect(relation.recipe_website_url).to eq(recipe_website_url)
          expect(relation.recipe_source_memo).to be_nil
        end
      end

      context "with other source" do
        let!(:other_source_record) { find_or_create_dish_source_of_other }
        let(:recipe_source_memo) { "テレビレシピ" }
        let(:recipe_locator) do
          ::Business::Food::Dish::Source::Locator::OtherRecipe.new(recipe_source_memo)
        end

        it "creates new dish source relation" do
          expect {
            described_class.put_dish_source_relation(dish_record.id, other_source_record.id, recipe_locator)
          }.to change { DishSourceRelation.count }.by(1)

          relation = DishSourceRelation.find_by(dish_id: dish_record.id)
          expect(relation.dish_source_id).to eq(other_source_record.id)
          expect(relation.recipe_book_page).to be_nil
          expect(relation.recipe_website_url).to be_nil
          expect(relation.recipe_source_memo).to eq(recipe_source_memo)
        end
      end
    end

    context "when existing relation exists" do
      let!(:existing_dish_source) { find_or_create_dish_source }
      let!(:existing_relation) do
        FactoryBot.create(
          :dish_source_relation,
          dish: dish_record,
          dish_source: existing_dish_source,
          recipe_book_page: 100,
        )
      end

      context "updating to different source" do
        let!(:new_source_record) { find_or_create_dish_source_of_youtube }
        let(:recipe_website_url) { "https://youtube.com/new-recipe" }
        let(:recipe_locator) do
          ::Business::Food::Dish::Source::Locator::RecipeWebsite.new(recipe_website_url)
        end

        it "updates existing relation" do
          expect {
            described_class.put_dish_source_relation(dish_record.id, new_source_record.id, recipe_locator)
          }.not_to change { DishSourceRelation.count }

          relation = DishSourceRelation.find_by(dish_id: dish_record.id)
          expect(relation.dish_source_id).to eq(new_source_record.id)
          expect(relation.recipe_book_page).to be_nil
          expect(relation.recipe_website_url).to eq(recipe_website_url)
          expect(relation.recipe_source_memo).to be_nil
        end
      end
    end
  end
end
