require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"
require_relative "../../../../../support/factories/dish_sources_repository"

RSpec.describe Business::Food::Dish::Usecase::UpdateCommand do
  let(:user_record) { find_or_create_user }
  let(:existing_dish_record) { find_or_create_dish }
  let(:dish_name) { "updated_dish_name" }
  let(:normalized_dish_name) { "updated_dish_name_normalized" }
  let(:meal_position) { 2 }
  let(:comment) { "updated_comment" }

  let(:valid_dish_params) do
    Business::Food::Dish::Usecase::Params::Dish.new(
      :update,
      id: existing_dish_record.id,
      name: dish_name,
      meal_position: meal_position,
      comment: comment
    )
  end

  before do
    allow(Business::Dish::Word::Normalize::Command::NormalizeCommand)
      .to receive(:call)
      .with(string_sequence: dish_name)
      .and_return(normalized_dish_name)
  end

  describe "#call" do
    describe "他エンティティ（集約ルート含む）との関連以外のプロパティ" do
      context "with valid parameters" do
        it "updates dish successfully and returns Business::Food::Dish::Root" do
          result = described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params
          )

          expect(result).to be_a(Business::Food::Dish::Root)
          expect(result.id).to eq(existing_dish_record.id)
          expect(result.user_id).to eq(user_record.id)
          expect(result.name.value).to eq(dish_name)
          expect(result.name.normalized).to eq(normalized_dish_name)
          expect(result.meal_position).to eq(meal_position)
          expect(result.comment).to eq(comment)
        end

        it "updates dish in database" do
          described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params
          )

          updated_dish = ::Dish.find(existing_dish_record.id)
          expect(updated_dish.name).to eq(dish_name)
          expect(updated_dish.normalized_name).to eq(normalized_dish_name)
          expect(updated_dish.meal_position).to eq(meal_position)
          expect(updated_dish.comment).to eq(comment)
        end

        context "when updating only name" do
          let(:name_only_params) do
            Business::Food::Dish::Usecase::Params::Dish.new(
              :update,
              id: existing_dish_record.id,
              name: dish_name
            )
          end

          it "updates only name" do
            result = described_class.call(
              user_id: user_record.id,
              dish_params: name_only_params
            )

            expect(result.name.value).to eq(dish_name)
            expect(result.name.normalized).to eq(normalized_dish_name)
            expect(result.meal_position).to eq(existing_dish_record.meal_position)
            expect(result.comment).to eq(existing_dish_record.comment)
          end
        end

        context "when updating only meal_position" do
          let(:position_only_params) do
            Business::Food::Dish::Usecase::Params::Dish.new(
              :update,
              id: existing_dish_record.id,
              meal_position: meal_position
            )
          end

          it "updates only meal_position" do
            result = described_class.call(
              user_id: user_record.id,
              dish_params: position_only_params
            )

            expect(result.name.value).to eq(existing_dish_record.name)
            expect(result.meal_position).to eq(meal_position)
            expect(result.comment).to eq(existing_dish_record.comment)
          end
        end

        context "when updating only comment" do
          let(:comment_only_params) do
            Business::Food::Dish::Usecase::Params::Dish.new(
              :update,
              id: existing_dish_record.id,
              comment: comment
            )
          end

          it "updates only comment" do
            result = described_class.call(
              user_id: user_record.id,
              dish_params: comment_only_params
            )

            expect(result.name.value).to eq(existing_dish_record.name)
            expect(result.meal_position).to eq(existing_dish_record.meal_position)
            expect(result.comment).to eq(comment)
          end
        end

        context "when clearing comment" do
          let(:clear_comment_params) do
            Business::Food::Dish::Usecase::Params::Dish.new(
              :update,
              id: existing_dish_record.id,
              comment: ""
            )
          end

          it "clears comment" do
            result = described_class.call(
              user_id: user_record.id,
              dish_params: clear_comment_params
            )

            expect(result.name.value).to eq(existing_dish_record.name)
            expect(result.meal_position).to eq(existing_dish_record.meal_position)
            expect(result.comment).to eq("")
          end
        end
      end

      context "when dish does not exist" do
        let(:non_existing_dish_params) do
          Business::Food::Dish::Usecase::Params::Dish.new(
            :update,
            id: 99999,
            name: dish_name
          )
        end

        it "raises error" do
          expect {
            described_class.call(
              user_id: user_record.id,
              dish_params: non_existing_dish_params
            )
          }.to raise_error("指定した料理は存在しません。")
        end
      end
    end

    describe "レシピ元との関連付け" do
      context "関連なし→関連なし" do
        it "レシピ元の関連なしのまま料理を更新できること" do
          described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params
          )

          dish_source_relation = ::Dish.find(existing_dish_record.id).dish_source_relation
          expect(dish_source_relation).to be nil
        end
      end

      context "関連なし→関連あり（レシピ本）" do
        context "レシピ本" do
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
            described_class.call(
              user_id: user_record.id,
              dish_params: valid_dish_params,
              dish_source_relation: dish_source_relation_params
            )

            dish_source_relation = ::Dish.find(existing_dish_record.id).dish_source_relation
            expect(dish_source_relation.dish_source_id).to eq dish_source_record.id
            expect(dish_source_relation.recipe_book_page).to eq recipe_book_page
            expect(dish_source_relation.recipe_website_url).to eq nil
            expect(dish_source_relation.recipe_source_memo).to eq nil
          end
        end

        context "Youtube" do
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
            described_class.call(
              user_id: user_record.id,
              dish_params: valid_dish_params,
              dish_source_relation: dish_source_relation_params
            )

            dish_source_relation = ::Dish.find(existing_dish_record.id).dish_source_relation
            expect(dish_source_relation.dish_source_id).to eq dish_source_record.id
            expect(dish_source_relation.recipe_book_page).to eq nil
            expect(dish_source_relation.recipe_website_url).to eq recipe_website_url
            expect(dish_source_relation.recipe_source_memo).to eq nil
          end
        end

        context "その他" do
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
            described_class.call(
              user_id: user_record.id,
              dish_params: valid_dish_params,
              dish_source_relation: dish_source_relation_params
            )

            dish_source_relation = ::Dish.find(existing_dish_record.id).dish_source_relation
            expect(dish_source_relation.dish_source_id).to eq dish_source_record.id
            expect(dish_source_relation.recipe_book_page).to eq nil
            expect(dish_source_relation.recipe_website_url).to eq nil
            expect(dish_source_relation.recipe_source_memo).to eq recipe_source_memo
          end
        end
      end

      context "関連あり→関連あり（別のレシピ元）" do
        let!(:dish_source_record_before) { find_or_create_dish_source }
        let!(:dish_source_relation_record) do
          FactoryBot.create(
            :dish_source_relation,
            dish: existing_dish_record,
            dish_source: dish_source_record_before,
            recipe_book_page: 32
          )
        end
        let!(:dish_source_record_after) { find_or_create_dish_source_of_youtube }
        let(:recipe_website_url) { "https://youtube.com/ryuji/gyoza" }
        let(:dish_source_relation_params) do
          Business::Food::Dish::Usecase::Params::DishSourceRelation.build_relation(
            dish_source_record_after.type,
            dish_source_record_after.id,
            recipe_website_url
          )
        end

        it "レシピ元が関連付けられること" do
          described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params,
            dish_source_relation: dish_source_relation_params
          )

          dish_source_relation = ::Dish.find(existing_dish_record.id).dish_source_relation
          expect(dish_source_relation.dish_source_id).to eq dish_source_record_after.id
          expect(dish_source_relation.recipe_book_page).to eq nil
          expect(dish_source_relation.recipe_website_url).to eq recipe_website_url
          expect(dish_source_relation.recipe_source_memo).to eq nil
        end
      end

      context "関連あり→関連なし" do
        let!(:dish_source_record) { find_or_create_dish_source }
        let!(:dish_source_relation_record) do
          FactoryBot.create(
            :dish_source_relation,
            dish: existing_dish_record,
            dish_source: dish_source_record,
            recipe_book_page: 32
          )
        end

        it "レシピ元が関連付けられること" do
          described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params,
          )

          dish_source_relation = ::Dish.find(existing_dish_record.id).dish_source_relation
          expect(dish_source_relation).to eq nil
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

    context "when dish_params is missing" do
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

    context "when dish_params is nil" do
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

  describe "タグ更新" do
    context "2つの既存タグがあり、1つ維持・1つ削除・1つ追加" do
      let!(:existing_tag1) { FactoryBot.create(:dish_tag, dish: existing_dish_record, user: user_record, content: "保持タグ", normalized_content: "保持タグ") }
      let!(:existing_tag2) { FactoryBot.create(:dish_tag, dish: existing_dish_record, user: user_record, content: "削除タグ", normalized_content: "削除タグ") }

      let(:tag_for_keep) do
        Business::Food::Dish::Tag::Usecase::Params::Tag.new(
          id: existing_tag1.id,
          content: "保持タグ",
          normalized_content: "保持タグ"
        )
      end

      let(:tag_for_add) do
        Business::Food::Dish::Tag::Usecase::Params::Tag.new(
          content: "新規タグ",
          normalized_content: "新規タグ"
        )
      end

      let(:dish_tags) { [tag_for_keep, tag_for_add] }

      it "例外が発生しない" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params,
            dish_source_relation: nil,
            dish_tags: dish_tags
          )
        }.not_to raise_error
      end

      it "既存タグ1つは維持、1つは削除、1つ新規追加される" do
        result = described_class.call(
          user_id: user_record.id,
          dish_params: valid_dish_params,
          dish_source_relation: nil,
          dish_tags: dish_tags
        )

        expect(result.tags.count).to eq(2)
        expect(result.tags[0].id).to eq(existing_tag1.id)
        expect(result.tags[0].content.value).to eq("保持タグ")
        expect(result.tags[1].content.value).to eq("新規タグ")
        created_dish_tag_record = DishTag.find_by(dish_id: existing_dish_record.id, content: "新規タグ")
        expect(result.tags[1].id).to eq(created_dish_tag_record.id)

        dish_tag_records = DishTag.where(dish_id: existing_dish_record.id)

        expect(dish_tag_records.count).to eq(2)
        expect(dish_tag_records.find_by(id: existing_tag1.id)).to be_present
        expect(dish_tag_records.find_by(id: existing_tag2.id)).to be_nil
        expect(dish_tag_records.find_by(content: "新規タグ")).to be_present
      end

      it "料理の基本属性も正しく更新される" do
        result = described_class.call(
          user_id: user_record.id,
          dish_params: valid_dish_params,
          dish_source_relation: nil,
          dish_tags: dish_tags
        )

        expect(result).to be_a(Business::Food::Dish::Root)
        expect(result.name.value).to eq(dish_name)
        expect(result.meal_position).to eq(meal_position)
        expect(result.comment).to eq(comment)

        updated_dish = Dish.find(existing_dish_record.id)
        expect(updated_dish.name).to eq(dish_name)
        expect(updated_dish.meal_position).to eq(meal_position)
        expect(updated_dish.comment).to eq(comment)
      end
    end
  end
end
