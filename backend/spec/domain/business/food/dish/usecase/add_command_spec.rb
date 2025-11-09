require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_sources_repository"

RSpec.describe Business::Food::Dish::Usecase::AddCommand do
  let(:user_record) { find_or_create_user }
  let(:dish_name) { "test_dish" }
  let(:normalized_dish_name) { "test_dish_normalized" }
  let(:meal_position) { 1 }
  let(:comment) { "test_comment" }

  let(:valid_dish_params) do
    Business::Food::Dish::Usecase::Params::Dish.new(
      :create,
      name: dish_name,
      meal_position: meal_position,
      comment: comment
    )
  end

  before do
    # Mock the normalize command
    allow(Business::Food::Dish::Word::Usecase::NormalizeCommand)
      .to receive(:call)
      .with(string_sequence: dish_name)
      .and_return(normalized_dish_name)
  end

  describe "#call" do
    context "with valid parameters" do
      it "creates dish successfully and returns Business::Food::Dish::Root" do
        result = described_class.call(
          user_id: user_record.id,
          dish_params: valid_dish_params
        )

        expect(result).to be_a(Business::Food::Dish::Root)
        expect(result.id).to be_present
        expect(result.user_id).to eq(user_record.id)
        expect(result.name.value).to eq(dish_name)
        expect(result.name.normalized).to eq(normalized_dish_name)
        expect(result.meal_position).to eq(meal_position)
        expect(result.comment).to eq(comment)
      end

      it "sets id after persistence" do
        result = described_class.call(
          user_id: user_record.id,
          dish_params: valid_dish_params
        )

        created_dish = ::Dish.last
        expect(result.id).to eq(created_dish.id)
      end

      it "saves dish to database" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params
          )
        }.to change { ::Dish.count }.by(1)

        created_dish = ::Dish.last
        expect(created_dish.user_id).to eq(user_record.id)
        expect(created_dish.name).to eq(dish_name)
        expect(created_dish.normalized_name).to eq(normalized_dish_name)
        expect(created_dish.meal_position).to eq(meal_position)
        expect(created_dish.comment).to eq(comment)
      end
    end

    describe "レシピ元との関連付け" do
      context "関連なしで作成" do
        it "レシピ元の関連なしで料理を作成できること" do
          result = described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params
          )

          dish_source_relation = ::Dish.find(result.id).dish_source_relation
          expect(dish_source_relation).to be nil
          expect(result.source_id).to be nil
          expect(result.source_locator).to be nil
        end
      end

      context "関連ありで作成（レシピ本）" do
        let!(:dish_source_record) { find_or_create_dish_source }
        let(:recipe_book_page) { 150 }
        let(:dish_source_relation_params) do
          Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
            dish_source_record.type,
            dish_source_record.id,
            recipe_book_page
          )
        end

        it "レシピ元が関連付けられること" do
          result = described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params,
            dish_source_relation: dish_source_relation_params
          )

          dish_source_relation = ::Dish.find(result.id).dish_source_relation
          expect(dish_source_relation.dish_source_id).to eq dish_source_record.id
          expect(dish_source_relation.recipe_book_page).to eq recipe_book_page
          expect(dish_source_relation.recipe_website_url).to eq nil
          expect(dish_source_relation.recipe_source_memo).to eq nil

          expect(result.source_id).to eq dish_source_record.id
          expect(result.source_locator).to be_a(Business::Food::Dish::Source::Locator::RecipeBook)
          expect(result.source_locator.page).to eq recipe_book_page
        end
      end

      context "関連ありで作成（Youtube）" do
        let!(:dish_source_record) { find_or_create_dish_source_of_youtube }
        let(:recipe_website_url) { "https://youtube.com/ryuji/gyoza" }
        let(:dish_source_relation_params) do
          Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
            dish_source_record.type,
            dish_source_record.id,
            recipe_website_url
          )
        end

        it "レシピ元が関連付けられること" do
          result = described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params,
            dish_source_relation: dish_source_relation_params
          )

          dish_source_relation = ::Dish.find(result.id).dish_source_relation
          expect(dish_source_relation.dish_source_id).to eq dish_source_record.id
          expect(dish_source_relation.recipe_book_page).to eq nil
          expect(dish_source_relation.recipe_website_url).to eq recipe_website_url
          expect(dish_source_relation.recipe_source_memo).to eq nil

          expect(result.source_id).to eq dish_source_record.id
          expect(result.source_locator).to be_a(Business::Food::Dish::Source::Locator::RecipeWebsite)
          expect(result.source_locator.url).to eq recipe_website_url
        end
      end

      context "関連ありで作成（その他）" do
        let!(:dish_source_record) { find_or_create_dish_source_of_other }
        let(:recipe_source_memo) { "駅最寄りの駐輪場を曲がったところ" }
        let(:dish_source_relation_params) do
          Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
            dish_source_record.type,
            dish_source_record.id,
            recipe_source_memo
          )
        end

        it "レシピ元が関連付けられること" do
          result = described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params,
            dish_source_relation: dish_source_relation_params
          )

          dish_source_relation = ::Dish.find(result.id).dish_source_relation
          expect(dish_source_relation.dish_source_id).to eq dish_source_record.id
          expect(dish_source_relation.recipe_book_page).to eq nil
          expect(dish_source_relation.recipe_website_url).to eq nil
          expect(dish_source_relation.recipe_source_memo).to eq recipe_source_memo

          expect(result.source_id).to eq dish_source_record.id
          expect(result.source_locator).to be_a(Business::Food::Dish::Source::Locator::OtherRecipe)
          expect(result.source_locator.memo).to eq recipe_source_memo
        end
      end
    end

    describe "タグ作成" do
      context "タグを指定した場合" do
        let(:dish_tags) do
          [
            Business::Food::Dish::Tag::Usecase::Params::Tag.new(
              content: "新規タグ",
              normalized_content: "新規タグ"
            )
          ]
        end

        it "タグが正しく作成される" do
          result = described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params,
            dish_tags: dish_tags
          )

          expect(result.tags.count).to eq(1)
          expect(result.tags.first.content.value).to eq("新規タグ")

          dish_tag_records = DishTag.where(dish_id: result.id)
          expect(dish_tag_records.count).to eq(1)
          expect(dish_tag_records.first.content).to eq("新規タグ")
        end
      end
    end
  end

  describe "validations" do
    context "when user_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(dish_params: valid_dish_params)
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when dish_param is missing" do
      it "raises validation error" do
        expect {
          described_class.call(user_id: user_record.id)
        }.to raise_error(/Dish params can't be blank/)
      end
    end

    context "when user_id is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: nil,
            dish_params: valid_dish_params
          )
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when dish_param is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_params: nil
          )
        }.to raise_error(/Dish params can't be blank/)
      end
    end
  end
end
