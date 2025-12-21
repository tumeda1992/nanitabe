# frozen_string_literal: true

require "rails_helper"
require_relative "../repository/repository_add_shared_examples"
require_relative "../repository/repository_remove_shared_examples"

module Business::Dish::Dish::Tag
  RSpec.describe Command::UpdateTagsCommand do
    context "when add tag, " do
      let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_TAG_SHOULD_BE_CREATED] }

      before do
        comparer.build_records_for_test()
      end

      it "adding succeeds" do
        described_class.call(
          user_id: comparer.prepared_records[:user_record].id,
          dish_id: comparer.prepared_records[:dish_record].id,
          dish_tags: [
            Command::Params::Tag.new(
              content: comparer.values[:content],
            ),
          ],
        )

        comparer.compare_to_expectation(self)
      end
    end

    context "when remove tag, " do
      let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_TAG_SHOULD_BE_REMOVED] }

      before do
        comparer.build_records_for_test()
      end

      it "removing succeeds" do
        described_class.call(
          user_id: comparer.prepared_records[:user_record].id,
          dish_id: comparer.prepared_records[:dish_record].id,
          dish_tags: [],
        )

        comparer.compare_to_expectation(self)
      end
    end

    context "when add tags, " do
      let!(:comparer) do
        comparer = ExpectationComparer.new("", {
          content1: "白ワインに合う",
          content2: "日本酒に合う",
        })

        comparer.define_required_records_for_test do
          {
            user_record: find_or_create_user(),
            dish_record: find_or_create_dish(),
          }
        end

        comparer.define_expectation do |expected_values, prepared_records|
          added_dish_tag_records = ::DishTag.last(2)

          added_dish_tag_record_1 = added_dish_tag_records[0]
          expect(added_dish_tag_record_1.user_id).to eq prepared_records[:user_record].id
          expect(added_dish_tag_record_1.dish_id).to eq prepared_records[:dish_record].id
          expect(added_dish_tag_record_1.content).to eq expected_values[:content1]

          added_dish_tag_record_2 = added_dish_tag_records[1]
          expect(added_dish_tag_record_2.user_id).to eq prepared_records[:user_record].id
          expect(added_dish_tag_record_2.dish_id).to eq prepared_records[:dish_record].id
          expect(added_dish_tag_record_2.content).to eq expected_values[:content2]
        end

        comparer
      end

      before do
        comparer.build_records_for_test()
      end

      it "adding succeeds" do
        described_class.call(
          user_id: comparer.prepared_records[:user_record].id,
          dish_id: comparer.prepared_records[:dish_record].id,
          dish_tags: [
            Command::Params::Tag.new(
              content: comparer.values[:content1],
            ),
            Command::Params::Tag.new(
              content: comparer.values[:content2],
            ),
          ],
        )

        comparer.compare_to_expectation(self)
      end
    end

    context "when want to remain an existing tag, add a new tag, and remove an existing tag, " do
      let!(:comparer) do
        comparer = ExpectationComparer.new("", {
          content: "簡単おつまみ",
        })

        comparer.define_required_records_for_test do
          {
            user_record: find_or_create_user(),
            dish_record: find_or_create_dish(),
            dish_tag_record: find_or_create_dish_tag(),
            dish_tag_record2: find_or_create_dish_tag2(),
          }
        end

        comparer.define_expectation do |expected_values, prepared_records|
          added_dish_evaluation_record = ::DishTag.last
          expect(added_dish_evaluation_record.user_id).to eq prepared_records[:user_record].id
          expect(added_dish_evaluation_record.dish_id).to eq prepared_records[:dish_record].id
          expect(added_dish_evaluation_record.content).to eq expected_values[:content]

          dish_tag_record = comparer.prepared_records[:dish_tag_record]
          existing_dish_tag_record = ::DishTag.find(dish_tag_record.id)
          expect(existing_dish_tag_record.id).to eq dish_tag_record.id
          expect(existing_dish_tag_record.user_id).to eq dish_tag_record.user_id
          expect(existing_dish_tag_record.dish_id).to eq dish_tag_record.dish_id
          expect(existing_dish_tag_record.content).to eq dish_tag_record.content

          expect(::DishTag.where(id: prepared_records[:dish_tag_record2].id).present?).to eq false
        end

        comparer
      end

      before do
        comparer.build_records_for_test()
      end

      it "updating succeeds" do
        described_class.call(
          user_id: comparer.prepared_records[:user_record].id,
          dish_id: comparer.prepared_records[:dish_record].id,
          dish_tags: [
            Command::Params::Tag.new(
              id: comparer.prepared_records[:dish_tag_record].id,
              content: comparer.prepared_records[:dish_tag_record].content,
            ),
            Command::Params::Tag.new(
              content: comparer.values[:content],
            ),
          ],
        )

        comparer.compare_to_expectation(self)
      end
    end

    context "when nothing changed, " do
      let!(:comparer) do
        comparer = ExpectationComparer.new("", {})

        comparer.define_required_records_for_test do
          {
            user_record: find_or_create_user(),
            dish_record: find_or_create_dish(),
            dish_tag_record: find_or_create_dish_tag(),
          }
        end

        comparer.define_expectation do |_expected_values, _prepared_records|
          dish_tag_record = comparer.prepared_records[:dish_tag_record]
          existing_dish_tag_record = ::DishTag.find(dish_tag_record.id)

          expect(existing_dish_tag_record.id).to eq dish_tag_record.id
          expect(existing_dish_tag_record.user_id).to eq dish_tag_record.user_id
          expect(existing_dish_tag_record.dish_id).to eq dish_tag_record.dish_id
          expect(existing_dish_tag_record.content).to eq dish_tag_record.content
        end

        comparer
      end

      before do
        comparer.build_records_for_test()
      end

      it "nothing changed" do
        described_class.call(
          user_id: comparer.prepared_records[:user_record].id,
          dish_id: comparer.prepared_records[:dish_record].id,
          dish_tags: [
            Command::Params::Tag.new(
              id: comparer.prepared_records[:dish_tag_record].id,
              content: comparer.prepared_records[:dish_tag_record].content,
            ),
          ],
        )

        comparer.compare_to_expectation(self)
      end
    end
  end
end
