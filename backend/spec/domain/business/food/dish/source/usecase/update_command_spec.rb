require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Dish::Source::Usecase::UpdateCommand do
  let(:user_record) { find_or_create_user }
  let(:existing_source_record) { FactoryBot.create(:dish_source, user: user_record) }
  let(:source_name) { "updated_source_name" }
  let(:source_type) { Business::Food::Dish::Source::Type.youtube.value }
  let(:comment) { "updated_comment" }

  let(:valid_source_params) do
    Business::Food::Dish::Source::Usecase::Params::Source.new(
      :update,
      id: existing_source_record.id,
      name: source_name,
      type: source_type,
      comment: comment,
    )
  end

  describe "#call" do
    context "with valid parameters" do
      it "updates source successfully and returns Business::Food::Dish::Source::Root" do
        result = described_class.call(
          user_id: user_record.id,
          source_params: valid_source_params,
        )

        expect(result).to be_a(Business::Food::Dish::Source::Root)
        expect(result.id).to eq(existing_source_record.id)
        expect(result.user_id).to eq(user_record.id)
        expect(result.name).to eq(source_name)
        expect(result.type.value).to eq(source_type)
        expect(result.comment).to eq(comment)
      end

      it "updates source in database" do
        described_class.call(
          user_id: user_record.id,
          source_params: valid_source_params,
        )

        updated_source = ::DishSource.find(existing_source_record.id)
        expect(updated_source.name).to eq(source_name)
        expect(updated_source.type).to eq(source_type)
        expect(updated_source.comment).to eq(comment)
      end

      context "when updating only name" do
        let(:name_only_params) do
          Business::Food::Dish::Source::Usecase::Params::Source.new(
            :update,
            id: existing_source_record.id,
            name: source_name,
          )
        end

        it "updates only name" do
          result = described_class.call(
            user_id: user_record.id,
            source_params: name_only_params,
          )

          expect(result.name).to eq(source_name)
          expect(result.type.value).to eq(existing_source_record.type)
          expect(result.comment).to eq(existing_source_record.comment)
        end
      end

      context "when updating only type" do
        let(:type_only_params) do
          Business::Food::Dish::Source::Usecase::Params::Source.new(
            :update,
            id: existing_source_record.id,
            type: source_type,
          )
        end

        it "updates only type" do
          result = described_class.call(
            user_id: user_record.id,
            source_params: type_only_params,
          )

          expect(result.name).to eq(existing_source_record.name)
          expect(result.type.value).to eq(source_type)
          expect(result.comment).to eq(existing_source_record.comment)
        end
      end

      context "when updating only comment" do
        let(:comment_only_params) do
          Business::Food::Dish::Source::Usecase::Params::Source.new(
            :update,
            id: existing_source_record.id,
            comment: comment,
          )
        end

        it "updates only comment" do
          result = described_class.call(
            user_id: user_record.id,
            source_params: comment_only_params,
          )

          expect(result.name).to eq(existing_source_record.name)
          expect(result.type.value).to eq(existing_source_record.type)
          expect(result.comment).to eq(comment)
        end
      end

      context "when clearing comment" do
        let(:clear_comment_params) do
          Business::Food::Dish::Source::Usecase::Params::Source.new(
            :update,
            id: existing_source_record.id,
            comment: "",
          )
        end

        it "clears comment" do
          result = described_class.call(
            user_id: user_record.id,
            source_params: clear_comment_params,
          )

          expect(result.name).to eq(existing_source_record.name)
          expect(result.type.value).to eq(existing_source_record.type)
          expect(result.comment).to eq("")
        end
      end
    end

    context "when source does not exist" do
      let(:non_existing_source_params) do
        Business::Food::Dish::Source::Usecase::Params::Source.new(
          :update,
          id: 99_999,
          name: source_name,
        )
      end

      it "raises error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            source_params: non_existing_source_params,
          )
        }.to raise_error("指定したレシピ元は存在しません。")
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
