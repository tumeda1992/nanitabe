require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"
require_relative "../../../../../support/factories/dish_sources_repository"

RSpec.describe Business::Food::Dish::Usecase::UpdateWithNewSourceCommand do
  # let(:user_record) { find_or_create_user }
  # let(:existing_dish_record) { find_or_create_dish }
  # let(:updated_dish_name) { "updated_dish_with_new_source" }
  # let(:normalized_dish_name) { "updated_dish_with_new_source_normalized" }
  # let(:updated_meal_position) { 2 }
  # let(:updated_dish_comment) { "updated_dish_comment" }
  #
  # let(:new_source_name) { "new_updated_source" }
  # let(:new_source_type) { Business::Food::Dish::Source::Type.recipe_book.value }
  # let(:new_source_comment) { "new_source_comment" }
  #
  # let(:valid_dish_params) do
  #   Business::Food::Dish::Usecase::Params::Dish.new(
  #     :update,
  #     id: existing_dish_record.id,
  #     name: updated_dish_name,
  #     meal_position: updated_meal_position,
  #     comment: updated_dish_comment
  #   )
  # end
  #
  # let(:valid_source_params) do
  #   Business::Food::Dish::Source::Usecase::Params::Source.new(
  #     :create,
  #     name: new_source_name,
  #     type: new_source_type,
  #     comment: new_source_comment
  #   )
  # end
  #
  # before do
  #   allow(Business::Dish::Word::Normalize::Command::NormalizeCommand)
  #     .to receive(:call)
  #     .with(string_sequence: updated_dish_name)
  #     .and_return(normalized_dish_name)
  # end
  #
  # describe "#call" do
  #   context "関連なし→関連あり（新しいYouTubeソース）" do
  #     let(:new_source_type) { Business::Food::Dish::Source::Type.youtube.value }
  #     let(:recipe_website_url) { "https://youtube.com/updated/recipe" }
  #     let(:dish_source_relation_params) do
  #       Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
  #         new_source_type,
  #         nil,
  #         recipe_website_url
  #       )
  #     end
  #
  #     it "新しいYouTubeソースを作成し、料理を更新して関連付けられること" do
  #       result = described_class.call(
  #         user_id: user_record.id,
  #         dish_params: valid_dish_params,
  #         source_params: valid_source_params,
  #         dish_source_relation: dish_source_relation_params
  #       )
  #
  #       expect(result).to be_a(Array)
  #       updated_dish, created_source_result = result
  #
  #       expect(updated_dish).to be_a(Business::Food::Dish::Root)
  #       expect(updated_dish.source_id).to be_present
  #       expect(updated_dish.source_locator).to be_a(Business::Food::Dish::Source::Locator::RecipeWebsite)
  #       expect(updated_dish.source_locator.url).to eq(recipe_website_url)
  #
  #       # ソースの戻り値が正しいこと
  #       expect(created_source_result).to be_a(Business::Food::Dish::Source::Root)
  #       expect(created_source_result.type.value).to eq(new_source_type)
  #
  #       # 新しいソースが正しいタイプで作成されていること
  #       created_source = ::DishSource.find(updated_dish.source_id)
  #       expect(created_source.type).to eq(new_source_type)
  #
  #       # 関連付けが作成されていること
  #       dish_source_relation = ::Dish.find(existing_dish_record.id).dish_source_relation
  #       expect(dish_source_relation.dish_source_id).to eq(updated_dish.source_id)
  #       expect(dish_source_relation.recipe_book_page).to eq nil
  #       expect(dish_source_relation.recipe_website_url).to eq(recipe_website_url)
  #       expect(dish_source_relation.recipe_source_memo).to eq nil
  #     end
  #   end
  #
  #   it "ソースの数が増加すること" do
  #     # テスト前に料理が確実に存在するように事前に参照
  #     existing_dish_record
  #
  #     dish_source_relation_params = Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
  #       new_source_type,
  #       nil,
  #       150
  #     )
  #
  #     expect {
  #       described_class.call(
  #         user_id: user_record.id,
  #         dish_params: valid_dish_params,
  #         source_params: valid_source_params,
  #         dish_source_relation: dish_source_relation_params
  #       )
  #     }.to change { ::DishSource.count }.by(1)
  #      .and change { ::DishSourceRelation.count }.by(1)
  #      .and change { ::Dish.count }.by(0) # 料理は更新されるだけなので増えない
  #   end
  #
  #   describe "タグ更新" do
  #     context "タグを指定した場合" do
  #       let(:dish_tags) do
  #         [
  #           Business::Food::Dish::Tag::Usecase::Params::Tag.new(
  #             content: "新規タグ",
  #             normalized_content: "新規タグ"
  #           )
  #         ]
  #       end
  #
  #       it "タグが正しく更新される" do
  #         result = described_class.call(
  #           user_id: user_record.id,
  #           dish_params: valid_dish_params,
  #           source_params: valid_source_params,
  #           dish_source_relation: Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(new_source_type, nil, 150),
  #           dish_tags: dish_tags
  #         )
  #
  #         updated_dish = result[0]
  #         expect(updated_dish.tags.count).to eq(1)
  #         expect(updated_dish.tags.first.content.value).to eq("新規タグ")
  #
  #         dish_tag_records = DishTag.where(dish_id: existing_dish_record.id)
  #         expect(dish_tag_records.count).to eq(1)
  #         expect(dish_tag_records.first.content).to eq("新規タグ")
  #       end
  #     end
  #   end
  # end
  #
  # describe "validations" do
  #   let(:recipe_book_page) { 150 }
  #   let(:dish_source_relation_params) do
  #     Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
  #       new_source_type,
  #       nil,
  #       recipe_book_page
  #     )
  #   end
  #
  #   context "when user_id is missing" do
  #     it "raises validation error" do
  #       expect {
  #         described_class.call(
  #           dish_params: valid_dish_params,
  #           source_params: valid_source_params,
  #           dish_source_relation: dish_source_relation_params
  #         )
  #       }.to raise_error(/User can't be blank/)
  #     end
  #   end
  #
  #   context "when dish_params is missing" do
  #     it "raises validation error" do
  #       expect {
  #         described_class.call(
  #           user_id: user_record.id,
  #           source_params: valid_source_params,
  #           dish_source_relation: dish_source_relation_params
  #         )
  #       }.to raise_error(/Dish params can't be blank/)
  #     end
  #   end
  #
  #   context "when source_params is missing" do
  #     it "raises validation error" do
  #       expect {
  #         described_class.call(
  #           user_id: user_record.id,
  #           dish_params: valid_dish_params,
  #           dish_source_relation: dish_source_relation_params
  #         )
  #       }.to raise_error(/Source params can't be blank/)
  #     end
  #   end
  #
  #   context "when dish_source_relation is missing" do
  #     it "raises validation error" do
  #       expect {
  #         described_class.call(
  #           user_id: user_record.id,
  #           dish_params: valid_dish_params,
  #           source_params: valid_source_params
  #         )
  #       }.to raise_error(/Dish source relation can't be blank/)
  #     end
  #   end
  #
  #   context "when dish does not exist" do
  #     let(:non_existing_dish_params) do
  #       Business::Food::Dish::Usecase::Params::Dish.new(
  #         :update,
  #         id: 99999,
  #         name: updated_dish_name
  #       )
  #     end
  #
  #     it "raises error" do
  #       expect {
  #         described_class.call(
  #           user_id: user_record.id,
  #           dish_params: non_existing_dish_params,
  #           source_params: valid_source_params,
  #           dish_source_relation: dish_source_relation_params
  #         )
  #       }.to raise_error("指定した料理は存在しません。")
  #     end
  #   end
  # end
end
