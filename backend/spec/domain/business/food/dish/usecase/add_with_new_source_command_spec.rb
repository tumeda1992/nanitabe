require "rails_helper"
require_relative "../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Dish::Usecase::AddWithNewSourceCommand do
  let(:user_record) { find_or_create_user }
  let(:dish_name) { "test_dish_with_new_source" }
  let(:normalized_dish_name) { "test_dish_with_new_source_normalized" }
  let(:meal_position) { 1 }
  let(:dish_comment) { "dish_comment" }

  let(:source_name) { "new_test_source" }
  let(:source_type) { Business::Food::Dish::Source::Type.recipe_book.value }
  let(:source_comment) { "source_comment" }

  let(:valid_dish_params) do
    Business::Food::Dish::Usecase::Params::Dish.new(
      :create,
      name: dish_name,
      meal_position: meal_position,
      comment: dish_comment
    )
  end

  let(:valid_source_params) do
    Business::Food::Dish::Source::Usecase::Params::Source.new(
      :create,
      name: source_name,
      type: source_type,
      comment: source_comment
    )
  end

  before do
    allow(Business::Dish::Word::Normalize::Command::NormalizeCommand)
      .to receive(:call)
      .with(string_sequence: dish_name)
      .and_return(normalized_dish_name)
  end

  describe "#call" do
    context "新しいレシピ本ソースと一緒に料理を作成" do
      let(:recipe_book_page) { 150 }
      let(:dish_source_relation_params) do
        Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
          source_type,
          nil,
          recipe_book_page
        )
      end

      it "新しいソースと料理を作成し、関連付けられること" do
        result = described_class.call(
          user_id: user_record.id,
          dish_params: valid_dish_params,
          source_params: valid_source_params,
          dish_source_relation: dish_source_relation_params
        )

        # 料理が正しく作成されていること
        expect(result).to be_a(Business::Food::Dish::Root)
        expect(result.id).to be_present
        expect(result.user_id).to eq(user_record.id)
        expect(result.name.value).to eq(dish_name)
        expect(result.name.normalized).to eq(normalized_dish_name)
        expect(result.meal_position).to eq(meal_position)
        expect(result.comment).to eq(dish_comment)

        # ソースが関連付けられていること
        expect(result.source_id).to be_present
        expect(result.source_locator).to be_a(Business::Food::Dish::Source::Locator::RecipeBook)
        expect(result.source_locator.page).to eq(recipe_book_page)

        # データベースに正しく保存されていること
        created_dish = ::Dish.find(result.id)
        expect(created_dish.name).to eq(dish_name)
        expect(created_dish.normalized_name).to eq(normalized_dish_name)
        expect(created_dish.meal_position).to eq(meal_position)
        expect(created_dish.comment).to eq(dish_comment)

        # ソースが作成されていること
        created_source = ::DishSource.find(result.source_id)
        expect(created_source.name).to eq(source_name)
        expect(created_source.type).to eq(source_type)
        expect(created_source.comment).to eq(source_comment)

        # 関連付けが作成されていること
        dish_source_relation = created_dish.dish_source_relation
        expect(dish_source_relation.dish_source_id).to eq(result.source_id)
        expect(dish_source_relation.recipe_book_page).to eq(recipe_book_page)
        expect(dish_source_relation.recipe_website_url).to eq nil
        expect(dish_source_relation.recipe_source_memo).to eq nil
      end
    end
  end

  describe "validations" do
    let(:recipe_book_page) { 150 }
    let(:dish_source_relation_params) do
      Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
        source_type,
        nil,
        recipe_book_page
      )
    end

    context "when user_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(
            dish_params: valid_dish_params,
            source_params: valid_source_params,
            dish_source_relation: dish_source_relation_params
          )
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when dish_params is missing" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            source_params: valid_source_params,
            dish_source_relation: dish_source_relation_params
          )
        }.to raise_error(/Dish params can't be blank/)
      end
    end

    context "when source_params is missing" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params,
            dish_source_relation: dish_source_relation_params
          )
        }.to raise_error(/Source params can't be blank/)
      end
    end

    context "when dish_source_relation is missing" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params,
            source_params: valid_source_params
          )
        }.to raise_error(/Dish source relation can't be blank/)
      end
    end
  end
end
