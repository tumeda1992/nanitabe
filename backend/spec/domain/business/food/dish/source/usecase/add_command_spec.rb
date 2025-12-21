require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Dish::Source::Usecase::AddCommand do
  let(:user_record) { find_or_create_user }
  let(:source_name) { "test_source" }
  let(:source_type) { Business::Food::Dish::Source::Type.recipe_book.value }
  let(:comment) { "test_comment" }

  let(:valid_source_params) do
    Business::Food::Dish::Source::Usecase::Params::Source.new(
      :create,
      name: source_name,
      type: source_type,
      comment: comment,
    )
  end

  describe "#call" do
    context "with valid parameters" do
      it "creates source successfully and returns Business::Food::Dish::Source::Root" do
        result = described_class.call(
          user_id: user_record.id,
          source_params: valid_source_params,
        )

        expect(result).to be_a(Business::Food::Dish::Source::Root)
        expect(result.id).to be_present
        expect(result.user_id).to eq(user_record.id)
        expect(result.name).to eq(source_name)
        expect(result.type.value).to eq(source_type)
        expect(result.comment).to eq(comment)
      end

      it "sets id after persistence" do
        result = described_class.call(
          user_id: user_record.id,
          source_params: valid_source_params,
        )

        created_source = ::DishSource.last
        expect(result.id).to eq(created_source.id)
      end

      it "saves source to database" do
        expect {
          described_class.call(
            user_id: user_record.id,
            source_params: valid_source_params,
          )
        }.to change { ::DishSource.count }.by(1)

        created_source = ::DishSource.last
        expect(created_source.user_id).to eq(user_record.id)
        expect(created_source.name).to eq(source_name)
        expect(created_source.type).to eq(source_type)
        expect(created_source.comment).to eq(comment)
      end
    end
  end

  describe "validations" do
    context "when user_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(source_params: valid_source_params)
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when source_params is missing" do
      it "raises validation error" do
        expect {
          described_class.call(user_id: user_record.id)
        }.to raise_error(/Source params can't be blank/)
      end
    end

    context "when user_id is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: nil,
            source_params: valid_source_params,
          )
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when source_params is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            source_params: nil,
          )
        }.to raise_error(/Source params can't be blank/)
      end
    end
  end
end
