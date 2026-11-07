require "rails_helper"
require_relative "../../../../graphql_auth_helper"

RSpec.describe "Meal frame pattern ownership", type: :request do
  let(:owner) { FactoryBot.create(:user, id_param: "pattern-owner") }
  let(:actor) { FactoryBot.create(:user, id_param: "pattern-actor") }
  let!(:pattern) { MealFramePattern.create!(user: owner, name: "original") }
  let!(:frame) { MealFrame.create!(user: owner, name: "frame") }
  let!(:entry) { MealFramePatternEntry.create!(meal_frame_pattern: pattern, meal_frame: frame, day_offset: 1, meal_type: 1) }
  let(:headers) { fetch_auth_header_values(existing_user_id: actor.id) }

  [false, true].each do |missing|
    context(missing ? "with a missing pattern" : "with a foreign pattern") do
      let(:target_id) { missing ? MealFramePattern.maximum(:id) + 1 : pattern.id }

      it "rejects updates without changing the pattern or its entries" do
        snapshot = [pattern.attributes, entry.attributes]
        query = "mutation { updateMealFramePattern(input: {mealFramePattern: {id: #{target_id}, name: \"changed\", entries: []}}) { mealFramePatternId } }"
        post("/graphql", params: { query: query, variables: {} }, as: :json, headers: headers)
        expect(response).to have_http_status(:not_found)
        expect([pattern.reload.attributes, entry.reload.attributes]).to eq(snapshot)
      end

      it "rejects deletion without deleting the pattern or its entries" do
        snapshot = [pattern.attributes, entry.attributes]
        query = "mutation { deleteMealFramePattern(input: {id: #{target_id}}) { mealFramePatternId } }"
        post("/graphql", params: { query: query, variables: {} }, as: :json, headers: headers)
        expect(response).to have_http_status(:not_found)
        expect([pattern.reload.attributes, entry.reload.attributes]).to eq(snapshot)
      end
    end
  end

  it "requires an actor for the update command" do
    expect {
      Business::Food::Meal::Frame::Pattern::Usecase::UpdateCommand.call(meal_frame_pattern_id: pattern.id, name: "changed")
    }.to raise_error(/User can't be blank/)
    expect(pattern.reload.name).to eq("original")
    expect(MealFramePatternEntry.exists?(entry.id)).to be(true)
  end

  it "requires an actor for the delete command" do
    expect {
      Business::Food::Meal::Frame::Pattern::Usecase::RemoveCommand.call(meal_frame_pattern_id: pattern.id)
    }.to raise_error(/User can't be blank/)
    expect(MealFramePattern.exists?(pattern.id)).to be(true)
    expect(MealFramePatternEntry.exists?(entry.id)).to be(true)
  end
end
