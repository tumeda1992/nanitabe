require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"
require_relative "../../../../../support/factories/dish_sources_repository"

RSpec.describe Business::Food::Dish::Usecase::UpdateWithNewSourceCommand do
  let(:user_record) { find_or_create_user }
  let(:existing_dish_record) { find_or_create_dish }
  let(:updated_dish_name) { "updated_dish_with_new_source" }
  let(:normalized_dish_name) { "updated_dish_with_new_source_normalized" }
  let(:updated_meal_position) { 2 }
  let(:updated_dish_comment) { "updated_dish_comment" }

  let(:new_source_name) { "new_updated_source" }
  let(:new_source_type) { Business::Food::Dish::Source::Type.recipe_book.value }
  let(:new_source_comment) { "new_source_comment" }

  let(:valid_dish_params) do
    Business::Food::Dish::Usecase::Params::Dish.new(
      :update,
      id: existing_dish_record.id,
      name: updated_dish_name,
      meal_position: updated_meal_position,
      comment: updated_dish_comment
    )
  end

  let(:valid_source_params) do
    Business::Food::Dish::Source::Usecase::Params::Source.new(
      :create,
      name: new_source_name,
      type: new_source_type,
      comment: new_source_comment
    )
  end

  before do
    allow(Business::Dish::Word::Normalize::Command::NormalizeCommand)
      .to receive(:call)
      .with(string_sequence: updated_dish_name)
      .and_return(normalized_dish_name)
  end

  describe "#call" do
    context "関連なし→関連あり（新しいレシピ本ソース）" do
      let(:recipe_book_page) { 200 }
      let(:dish_source_relation_params) do
        Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
          new_source_type,
          nil, # dish_source_id is nil for new source
          recipe_book_page
        )
      end

      it "新しいソースを作成し、料理を更新して関連付けられること" do
        result = described_class.call(
          user_id: user_record.id,
          dish_params: valid_dish_params,
          source_params: valid_source_params,
          dish_source_relation: dish_source_relation_params
        )

        # 料理が正しく更新されていること
        expect(result).to be_a(Business::Food::Dish::Root)
        expect(result.id).to eq(existing_dish_record.id)
        expect(result.user_id).to eq(user_record.id)
        expect(result.name.value).to eq(updated_dish_name)
        expect(result.name.normalized).to eq(normalized_dish_name)
        expect(result.meal_position).to eq(updated_meal_position)
        expect(result.comment).to eq(updated_dish_comment)

        # 新しいソースが関連付けられていること
        expect(result.source_id).to be_present
        expect(result.source_locator).to be_a(Business::Food::Dish::Source::Locator::RecipeBook)
        expect(result.source_locator.page).to eq(recipe_book_page)

        # データベースが正しく更新されていること
        updated_dish = ::Dish.find(existing_dish_record.id)
        expect(updated_dish.name).to eq(updated_dish_name)
        expect(updated_dish.normalized_name).to eq(normalized_dish_name)
        expect(updated_dish.meal_position).to eq(updated_meal_position)
        expect(updated_dish.comment).to eq(updated_dish_comment)

        # 新しいソースが作成されていること
        created_source = ::DishSource.find(result.source_id)
        expect(created_source.name).to eq(new_source_name)
        expect(created_source.type).to eq(new_source_type)
        expect(created_source.comment).to eq(new_source_comment)

        # 関連付けが作成されていること
        dish_source_relation = updated_dish.dish_source_relation
        expect(dish_source_relation.dish_source_id).to eq(result.source_id)
        expect(dish_source_relation.recipe_book_page).to eq(recipe_book_page)
        expect(dish_source_relation.recipe_website_url).to eq nil
        expect(dish_source_relation.recipe_source_memo).to eq nil
      end
    end

    context "関連なし→関連あり（新しいYouTubeソース）" do
      let(:new_source_type) { Business::Food::Dish::Source::Type.youtube.value }
      let(:recipe_website_url) { "https://youtube.com/updated/recipe" }
      let(:dish_source_relation_params) do
        Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
          new_source_type,
          nil,
          recipe_website_url
        )
      end

      it "新しいYouTubeソースを作成し、料理を更新して関連付けられること" do
        result = described_class.call(
          user_id: user_record.id,
          dish_params: valid_dish_params,
          source_params: valid_source_params,
          dish_source_relation: dish_source_relation_params
        )

        expect(result).to be_a(Business::Food::Dish::Root)
        expect(result.source_id).to be_present
        expect(result.source_locator).to be_a(Business::Food::Dish::Source::Locator::RecipeWebsite)
        expect(result.source_locator.url).to eq(recipe_website_url)

        # 新しいソースが正しいタイプで作成されていること
        created_source = ::DishSource.find(result.source_id)
        expect(created_source.type).to eq(new_source_type)

        # 関連付けが作成されていること
        dish_source_relation = ::Dish.find(existing_dish_record.id).dish_source_relation
        expect(dish_source_relation.dish_source_id).to eq(result.source_id)
        expect(dish_source_relation.recipe_book_page).to eq nil
        expect(dish_source_relation.recipe_website_url).to eq(recipe_website_url)
        expect(dish_source_relation.recipe_source_memo).to eq nil
      end
    end

    context "関連なし→関連あり（新しいその他ソース）" do
      let(:new_source_type) { Business::Food::Dish::Source::Type.other.value }
      let(:recipe_source_memo) { "新しいお店情報メモ" }
      let(:dish_source_relation_params) do
        Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
          new_source_type,
          nil,
          recipe_source_memo
        )
      end

      it "新しいその他ソースを作成し、料理を更新して関連付けられること" do
        result = described_class.call(
          user_id: user_record.id,
          dish_params: valid_dish_params,
          source_params: valid_source_params,
          dish_source_relation: dish_source_relation_params
        )

        expect(result).to be_a(Business::Food::Dish::Root)
        expect(result.source_id).to be_present
        expect(result.source_locator).to be_a(Business::Food::Dish::Source::Locator::OtherRecipe)
        expect(result.source_locator.memo).to eq(recipe_source_memo)

        # 新しいソースが正しいタイプで作成されていること
        created_source = ::DishSource.find(result.source_id)
        expect(created_source.type).to eq(new_source_type)

        # 関連付けが作成されていること
        dish_source_relation = ::Dish.find(existing_dish_record.id).dish_source_relation
        expect(dish_source_relation.dish_source_id).to eq(result.source_id)
        expect(dish_source_relation.recipe_book_page).to eq nil
        expect(dish_source_relation.recipe_website_url).to eq nil
        expect(dish_source_relation.recipe_source_memo).to eq(recipe_source_memo)
      end
    end

    context "関連あり→関連あり（既存ソースから新しいソースに変更）" do
      let!(:existing_source_record) { find_or_create_dish_source }
      let!(:dish_source_relation_record) do
        FactoryBot.create(
          :dish_source_relation,
          dish: existing_dish_record,
          dish_source: existing_source_record,
          recipe_book_page: 100
        )
      end
      
      let(:new_source_type) { Business::Food::Dish::Source::Type.youtube.value }
      let(:recipe_website_url) { "https://youtube.com/new/recipe" }
      let(:dish_source_relation_params) do
        Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
          new_source_type,
          nil,
          recipe_website_url
        )
      end

      it "既存の関連付けを新しいソースに変更すること" do
        result = described_class.call(
          user_id: user_record.id,
          dish_params: valid_dish_params,
          source_params: valid_source_params,
          dish_source_relation: dish_source_relation_params
        )

        expect(result).to be_a(Business::Food::Dish::Root)
        expect(result.source_id).to be_present
        expect(result.source_id).not_to eq(existing_source_record.id) # 新しいソースのIDになっている
        expect(result.source_locator).to be_a(Business::Food::Dish::Source::Locator::RecipeWebsite)
        expect(result.source_locator.url).to eq(recipe_website_url)

        # 新しいソースが作成されていること
        created_source = ::DishSource.find(result.source_id)
        expect(created_source.name).to eq(new_source_name)
        expect(created_source.type).to eq(new_source_type)

        # 関連付けが新しいソースに変更されていること
        dish_source_relation = ::Dish.find(existing_dish_record.id).dish_source_relation
        expect(dish_source_relation.dish_source_id).to eq(result.source_id)
        expect(dish_source_relation.recipe_book_page).to eq nil
        expect(dish_source_relation.recipe_website_url).to eq(recipe_website_url)
        expect(dish_source_relation.recipe_source_memo).to eq nil
      end
    end

    it "ソースの数が増加すること" do
      # テスト前に料理が確実に存在するように事前に参照
      existing_dish_record
      
      dish_source_relation_params = Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
        new_source_type,
        nil,
        150
      )

      expect {
        described_class.call(
          user_id: user_record.id,
          dish_params: valid_dish_params,
          source_params: valid_source_params,
          dish_source_relation: dish_source_relation_params
        )
      }.to change { ::DishSource.count }.by(1)
       .and change { ::DishSourceRelation.count }.by(1)
       .and change { ::Dish.count }.by(0) # 料理は更新されるだけなので増えない
    end
  end

  describe "validations" do
    let(:recipe_book_page) { 150 }
    let(:dish_source_relation_params) do
      Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
        new_source_type,
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

    context "when dish does not exist" do
      let(:non_existing_dish_params) do
        Business::Food::Dish::Usecase::Params::Dish.new(
          :update,
          id: 99999,
          name: updated_dish_name
        )
      end

      it "raises error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_params: non_existing_dish_params,
            source_params: valid_source_params,
            dish_source_relation: dish_source_relation_params
          )
        }.to raise_error("指定した料理は存在しません。")
      end
    end
  end
end