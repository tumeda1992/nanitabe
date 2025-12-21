# frozen_string_literal: true

require "rails_helper"
require_relative "../repository/repository_add_shared_examples"
require_relative "../repository/repository_put_dish_relation_shared_examples"
require_relative "../source/repository/repository_add_shared_examples"
require_relative "../repository/repository_remove_dish_relation_shared_examples"
require_relative "../tag/repository/repository_add_shared_examples"

module Business::Dish::Dish
  RSpec.describe Command::CreateWithNewSourceCommand do
    describe ".call" do
      # CreateCommandのテストとの差分、つまりUpdateWithNewSourceCommandゆえのテストを記載

      before do
        dish_comparer.build_records_for_test()
        dish_source_comparer.build_records_for_test()
        dish_source_relation_comparer.build_records_for_test()
      end

      context "when create dish with new source relation, " do
        let!(:dish_comparer) { COMPARERS[KEY_OF_TEST_DISH_SHOULD_BE_CREATED] }
        let!(:dish_source_comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_SHOULD_BE_CREATED] }
        let!(:dish_source_relation_comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_CREATED] }

        it "creating succeeds" do
          created_dish, created_dish_source = described_class.call(
            user_id: dish_comparer.prepared_records[:user_record].id,
            dish_for_create: Command::Params::DishForCreate.new(
              name: dish_comparer.values[:name],
              meal_position: dish_comparer.values[:meal_position],
              comment: dish_comparer.values[:comment],
            ),
            dish_source_for_create: Source::Command::Params::SourceForCreate.new(
              name: dish_source_comparer.values[:name],
              type: dish_source_comparer.values[:type],
              comment: dish_source_comparer.values[:comment],
            ),
            dish_source_relation_detail: Command::Params::DishSourceRelation.build_relation_detail(
              dish_source_comparer.values[:type],
              dish_source_relation_comparer.values[:recipe_book_page],
            ),
          )

          dish_comparer.compare_to_expectation(self)
          dish_source_comparer.compare_to_expectation(self)
          dish_source_relation_comparer.compare_to_expectation(
            self,
            dish_id: created_dish.id,
            dish_source_id: created_dish_source.id,
          )
        end
      end

      context "when create dish with new source relation without detail value, " do
        let!(:dish_comparer) { COMPARERS[KEY_OF_TEST_DISH_SHOULD_BE_CREATED] }
        let!(:dish_source_comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_SHOULD_BE_CREATED] }
        let!(:dish_source_relation_comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_RELATION_OF_OTHER_WITHOUT_DETAIL_VALUE_SHOULD_BE_CREATED] }

        it "creating succeeds" do
          created_dish, created_dish_source = described_class.call(
            user_id: dish_comparer.prepared_records[:user_record].id,
            dish_for_create: Command::Params::DishForCreate.new(
              name: dish_comparer.values[:name],
              meal_position: dish_comparer.values[:meal_position],
              comment: dish_comparer.values[:comment],
            ),
            dish_source_for_create: Source::Command::Params::SourceForCreate.new(
              name: dish_source_comparer.values[:name],
              type: dish_source_comparer.values[:type],
              comment: dish_source_comparer.values[:comment],
            ),
            dish_source_relation_detail: Command::Params::DishSourceRelation.build_relation_detail(
              dish_source_comparer.values[:type],
              dish_source_relation_comparer.values[:recipe_source_memo],
            ),
          )

          dish_comparer.compare_to_expectation(self)
          dish_source_comparer.compare_to_expectation(self)
          dish_source_relation_comparer.compare_to_expectation(
            self,
            dish_id: created_dish.id,
            dish_source_id: created_dish_source.id,
          )
        end
      end

      context "when create dish with new source relation and new tag, " do # newが2つに見えて差分はtagのみ
        let!(:dish_comparer) { COMPARERS[KEY_OF_TEST_DISH_SHOULD_BE_CREATED] }
        let!(:dish_source_comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_SHOULD_BE_CREATED] }
        let!(:dish_source_relation_comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_CREATED] }
        let!(:dish_tag_comparer) { COMPARERS[KEY_OF_TEST_DISH_TAG_SHOULD_BE_CREATED] }

        it "creating succeeds" do
          dish_tag_comparer.build_records_for_test()

          created_dish, created_dish_source = described_class.call(
            user_id: dish_comparer.prepared_records[:user_record].id,
            dish_for_create: Command::Params::DishForCreate.new(
              name: dish_comparer.values[:name],
              meal_position: dish_comparer.values[:meal_position],
              comment: dish_comparer.values[:comment],
            ),
            dish_source_for_create: Source::Command::Params::SourceForCreate.new(
              name: dish_source_comparer.values[:name],
              type: dish_source_comparer.values[:type],
              comment: dish_source_comparer.values[:comment],
            ),
            dish_source_relation_detail: Command::Params::DishSourceRelation.build_relation_detail(
              dish_source_comparer.values[:type],
              dish_source_relation_comparer.values[:recipe_book_page],
            ),
            dish_tags: [
              ::Business::Dish::Dish::Tag::Command::Params::Tag.new(
                content: dish_tag_comparer.values[:content],
              ),
            ],
          )

          dish_comparer.compare_to_expectation(self)
          dish_source_comparer.compare_to_expectation(self)
          dish_source_relation_comparer.compare_to_expectation(
            self,
            dish_id: created_dish.id,
            dish_source_id: created_dish_source.id,
          )
          dish_tag_comparer.compare_to_expectation(self, dish_id: created_dish.id)
        end
      end
    end
  end
end
