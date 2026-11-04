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

      context "when update dish source relation to different source type detail," do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_UPDATED_TO_DIFFERENT_SOURCE_TYPE_DETAIL] }
        it "updating succeeds" do
          source_command_class = ::Business::Dish::Dish::Source::Command
          source_command_class::UpdateCommand.call(
            user_id: comparer.prepared_records[:user_record].id,
            dish_source_for_update: source_command_class::Params::SourceForUpdate.new(
              id: comparer.prepared_records[:dish_source_record].id,
              type: ::Business::Dish::Dish::Source::Type::YOUTUBE,
            ),
          )
          described_class.put_dish_source_relation(
            comparer.prepared_records[:dish_record].id,
            comparer.prepared_records[:dish_source_record].id,
            comparer.values,
          )

          comparer.compare_to_expectation(self)
        end
      end
    end
  end
end
