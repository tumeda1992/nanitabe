# frozen_string_literal: true

require "rails_helper"
require_relative "./repository_put_dish_relation_shared_examples"

module Business::Dish::Dish
  RSpec.describe Repository do
    describe ".put_dish_relation" do
      before do
        comparer.build_records_for_test()
      end

      context "when add dish source relation," do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_CREATED] }
        it "adding succeeds" do
          described_class.put_dish_source_relation(
            comparer.prepared_records[:dish_record].id,
            comparer.prepared_records[:dish_source_record].id,
            comparer.values,
          )

          comparer.compare_to_expectation(self)
        end
      end

      context "when add dish source relation of youtube," do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_RELATION_OF_YOUTUBE_SHOULD_BE_CREATED] }
        it "adding succeeds" do
          described_class.put_dish_source_relation(
            comparer.prepared_records[:dish_record].id,
            comparer.prepared_records[:dish_source_record].id,
            comparer.values,
          )

          comparer.compare_to_expectation(self)
        end
      end

      context "when add dish source relation of other," do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_RELATION_OF_OTHER_SHOULD_BE_CREATED] }
        it "adding succeeds" do
          described_class.put_dish_source_relation(
            comparer.prepared_records[:dish_record].id,
            comparer.prepared_records[:dish_source_record].id,
            comparer.values,
          )

          comparer.compare_to_expectation(self)
        end
      end

      context "when update dish source relation," do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_UPDATED] }
        it "updating succeeds" do
          described_class.put_dish_source_relation(
            comparer.prepared_records[:dish_record].id,
            comparer.prepared_records[:dish_source_record].id,
            comparer.values,
          )

          comparer.compare_to_expectation(self)
        end
      end

      context "when changing the type of a source that already has related dishes," do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_UPDATED] }
        it "rejects the change and preserves the source and relation" do
          source = comparer.prepared_records[:dish_source_record]
          relation = comparer.prepared_records[:dish_source_relation_record]
          before = [source.attributes, relation.attributes]
          source_command_class = ::Business::Dish::Dish::Source::Command
          expect {
            source_command_class::UpdateCommand.call(
              user_id: comparer.prepared_records[:user_record].id,
              dish_source_for_update: source_command_class::Params::SourceForUpdate.new(
                id: source.id,
                type: ::Business::Dish::Dish::Source::Type::YOUTUBE,
              ),
            )
          }.to raise_error(ActiveRecord::RecordInvalid, /料理が関連付けられているレシピ元/)
          expect([source.reload.attributes, relation.reload.attributes]).to eq(before)
        end
      end

      context "when replacing stale detail columns on an existing YouTube source relation," do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_RELATION_OF_YOUTUBE_SHOULD_BE_CREATED] }
        it "writes the URL and clears obsolete book details without changing source type" do
          # Legacy rows can already contain stale columns; creating a YouTube source does not retype a linked source.
          relation = ::DishSourceRelation.create!(
            dish_id: comparer.prepared_records[:dish_record].id,
            dish_source_id: comparer.prepared_records[:dish_source_record].id,
            recipe_book_page: 42,
          )
          described_class.put_dish_source_relation(
            comparer.prepared_records[:dish_record].id,
            comparer.prepared_records[:dish_source_record].id,
            comparer.values,
          )

          comparer.compare_to_expectation(self)
          expect(relation.reload.recipe_book_page).to be_nil
        end
      end
    end
  end
end
