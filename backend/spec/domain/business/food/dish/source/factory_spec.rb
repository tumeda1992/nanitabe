require "rails_helper"
require_relative "../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Dish::Source::Factory do
  let(:user_record) { find_or_create_user }
  let(:source_name) { "test_source" }
  let(:source_type) { Business::Food::Dish::Source::Type.recipe_book }
  let(:comment) { "test_comment" }

  describe ".build" do
    context "with valid parameters" do
      it "creates source successfully and returns Business::Food::Dish::Source::Root" do
        result = described_class.build(
          user_record.id,
          source_name,
          source_type,
          comment: comment,
        )

        expect(result).to be_a(Business::Food::Dish::Source::Root)
        expect(result.user_id).to eq(user_record.id)
        expect(result.name).to eq(source_name)
        expect(result.type.value).to eq(source_type.value)
        expect(result.comment).to eq(comment)
      end

      it "creates source without comment" do
        result = described_class.build(
          user_record.id,
          source_name,
          source_type,
        )

        expect(result).to be_a(Business::Food::Dish::Source::Root)
        expect(result.user_id).to eq(user_record.id)
        expect(result.name).to eq(source_name)
        expect(result.type.value).to eq(source_type.value)
        expect(result.comment).to be_nil
      end

      it "accepts type as integer value" do
        result = described_class.build(
          user_record.id,
          source_name,
          source_type.value,
          comment: comment,
        )

        expect(result).to be_a(Business::Food::Dish::Source::Root)
        expect(result.type.value).to eq(source_type.value)
      end
    end

    context "with invalid parameters" do
      it "raises validation error when user_id is missing" do
        expect {
          described_class.build(
            nil,
            source_name,
            source_type,
          )
        }.to raise_error(/User can't be blank/)
      end

      it "raises validation error when name is missing" do
        expect {
          described_class.build(
            user_record.id,
            nil,
            source_type,
          )
        }.to raise_error(/Name can't be blank/)
      end

      it "raises validation error when type is missing" do
        expect {
          described_class.build(
            user_record.id,
            source_name,
            nil,
          )
        }.to raise_error(/Type can't be blank/)
      end
    end
  end

  describe ".build_existing_from_id" do
    let(:existing_source_record) { FactoryBot.create(:dish_source, user: user_record) }

    context "when source exists" do
      it "returns Business::Food::Dish::Source::Root" do
        result = described_class.build_existing_from_id(existing_source_record.id)

        expect(result).to be_a(Business::Food::Dish::Source::Root)
        expect(result.id).to eq(existing_source_record.id)
        expect(result.user_id).to eq(existing_source_record.user_id)
        expect(result.name).to eq(existing_source_record.name)
        expect(result.type.value).to eq(existing_source_record.type)
        expect(result.comment).to eq(existing_source_record.comment)
      end
    end

    context "when source does not exist" do
      it "returns nil" do
        result = described_class.build_existing_from_id(99_999)

        expect(result).to be_nil
      end
    end
  end
end
