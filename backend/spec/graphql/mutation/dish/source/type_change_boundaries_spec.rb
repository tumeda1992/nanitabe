require "rails_helper"
require_relative "../../../graphql_auth_helper"

RSpec.describe "Source type changes preserve related recipe details", type: :request do
  let(:owner) { FactoryBot.create(:user, id_param: "source-type-owner") }
  let(:source) { FactoryBot.create(:dish_source, user: owner) }
  let(:types) { Business::Food::Dish::Source::Type }
  let(:rejection) { "料理が関連付けられているレシピ元の種別は変更できません。" }

  def attach_book_recipes
    [42, 64].map do |page|
      dish = FactoryBot.create(:dish, user: owner)
      FactoryBot.create(:dish_source_relation, dish: dish, dish_source: source, recipe_book_page: page)
      dish
    end
  end

  def snapshots
    [source.reload.attributes, Dish.order(:id).map(&:attributes), DishSourceRelation.order(:dish_id).map(&:attributes)]
  end

  %i[model legacy current graphql].each do |entrypoint|
    context "through #{entrypoint}" do
      define_method(:perform_update) do |attributes, expected_status = :success|
        case entrypoint
        when :model
          source.update!(attributes)
        when :legacy
          Business::Dish::Dish::Source::Command::UpdateCommand.call(
            user_id: owner.id,
            dish_source_for_update: Business::Dish::Dish::Source::Command::Params::SourceForUpdate.new(id: source.id, **attributes),
          )
        when :current
          Business::Food::Dish::Source::Usecase::UpdateCommand.call(
            user_id: owner.id,
            source_params: Business::Food::Dish::Source::Usecase::Params::Source.new(:update, id: source.id, **attributes),
          )
        when :graphql
          query = <<~GRAPHQL
            mutation updateSource($dishSource: SourceForUpdate!) {
              updateDishSource(input: {dishSource: $dishSource}) { dishSourceId }
            }
          GRAPHQL
          headers = fetch_auth_header_values(existing_user_id: owner.id)
          post "/graphql", params: { query: query, variables: { dishSource: { id: source.id, **attributes } } },
                           headers: headers, as: :json
          expect(response).to have_http_status(expected_status)
          if expected_status == :success
            expect(response.parsed_body.dig("data", "updateDishSource", "dishSourceId")).to eq(source.id)
          else
            expect(response.body).to include(rejection)
          end
        end
      end

      define_method(:expect_rejected_update) do |attributes|
        if entrypoint == :graphql
          perform_update(attributes, :unprocessable_entity)
        else
          expect { perform_update(attributes) }.to raise_error(ActiveRecord::RecordInvalid) do |error|
            expect(error.record.errors[:type]).to include(rejection)
          end
        end
      end

      it "rejects a book-to-web change including simultaneous name/comment changes" do
        attach_book_recipes
        before = snapshots
        expect_rejected_update(type: types::WEBSITE, name: "変更不可", comment: "変更不可")
        expect(snapshots).to eq(before)
      end

      it "keeps pages visible and re-savable after a rejection and an update of the original type" do
        dishes = attach_book_recipes
        expect_rejected_update(type: types::WEBSITE)
        perform_update(type: types::RECIPE_BOOK, name: "本の改名", comment: "追記")
        expect(source.reload.name).to eq("本の改名")
        expect(dishes.map { |dish| Dish.build_existing_root_from_id(dish.id).source_locator.detail_value }).to eq([42, 64])
        dishes.each { |dish| Dish.persist_from_food_dish_root(Dish.build_existing_root_from_id(dish.id)) }
        expect(DishSourceRelation.order(:dish_id).pluck(:recipe_book_page)).to eq([42, 64])
      end

      it "permits a same-type rename and comment update with related dishes" do
        attach_book_recipes
        perform_update(type: types::RECIPE_BOOK, name: "本の改名", comment: "追記")
        expect(source.reload.attributes.slice("type", "name", "comment")).to eq(
          "type" => types::RECIPE_BOOK, "name" => "本の改名", "comment" => "追記",
        )
        expect(DishSourceRelation.order(:dish_id).pluck(:recipe_book_page)).to eq([42, 64])
      end

      it "permits a type change when there are no related dishes" do
        perform_update(type: types::WEBSITE, name: "Web出典", comment: "追記")
        expect(source.reload.attributes.slice("type", "name", "comment")).to eq(
          "type" => types::WEBSITE, "name" => "Web出典", "comment" => "追記",
        )
      end

      it "rejects a related YouTube-to-web change even though both use URL locators" do
        source.update!(type: types::YOUTUBE)
        dish = FactoryBot.create(:dish, user: owner)
        FactoryBot.create(:dish_source_relation, dish: dish, dish_source: source, recipe_website_url: "https://example.invalid/recipe")
        before = snapshots
        expect_rejected_update(type: types::WEBSITE)
        expect(snapshots).to eq(before)
      end
    end
  end
end
