require "rails_helper"
require_relative "../../../../graphql_auth_helper"

RSpec.describe "Pattern frame references", type: :request do
  let(:actor) { FactoryBot.create(:user, id_param: "pattern-frame-actor") }
  let(:owner) { FactoryBot.create(:user, id_param: "pattern-frame-owner") }
  let!(:own_frame) { MealFrame.create!(user: actor, name: "own") }
  let!(:foreign_frame) { MealFrame.create!(user: owner, name: "private frame") }
  let!(:pattern) { MealFramePattern.create!(user: actor, name: "original") }
  let!(:entry) { MealFramePatternEntry.create!(meal_frame_pattern: pattern, meal_frame: own_frame, day_offset: 1, meal_type: 1) }
  let(:headers) { fetch_auth_header_values(existing_user_id: actor.id) }
  let(:entries_input) { "[{dayOffset: 1, mealType: 1, mealFrameId: #{own_frame.id}}, {dayOffset: 2, mealType: 1, mealFrameId: #{foreign_frame.id}}]" }

  it "rolls back a new pattern with any foreign frame" do
    headers
    counts = [MealFramePattern.count, MealFramePatternEntry.count]
    query = "mutation { addMealFramePattern(input: {mealFramePattern: {name: \"new\", entries: #{entries_input}}}) { mealFramePatternId } }"
    post("/graphql", params: { query: query }, as: :json, headers: headers)
    expect(response).to have_http_status(:not_found)
    expect([MealFramePattern.count, MealFramePatternEntry.count]).to eq(counts)
  end

  it "rolls back the name and all entries when an update refers to a foreign frame" do
    snapshot = [pattern.attributes, entry.attributes]
    query = "mutation { updateMealFramePattern(input: {mealFramePattern: {id: #{pattern.id}, name: \"changed\", entries: #{entries_input}}}) { mealFramePatternId } }"
    post("/graphql", params: { query: query }, as: :json, headers: headers)
    expect(response).to have_http_status(:not_found)
    expect([pattern.reload.attributes, entry.reload.attributes]).to eq(snapshot)
    expect(pattern.meal_frame_pattern_entries.count).to eq(1)
  end

  it "rejects a foreign frame at the child command boundary" do
    expect {
      Business::Food::Meal::Frame::Pattern::Entry::Usecase::AddCommand.call(
        meal_frame_pattern_id: pattern.id, day_offset: 2, meal_type: 1, meal_frame_id: foreign_frame.id,
      )
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect(pattern.meal_frame_pattern_entries.count).to eq(1)
  end

  it "does not return foreign entries from an existing malformed pattern" do
    bad_entry = MealFramePatternEntry.create!(meal_frame_pattern: pattern, meal_frame: foreign_frame, day_offset: 2, meal_type: 1)
    data = fetch_mutation_with_auth("query { mealFramePatterns { id entries { id mealFrameId mealFrameName } } }", {}, actor.id)
    expect(data["mealFramePatterns"].first["entries"]).to eq([
                                                               { "id" => entry.id, "mealFrameId" => own_frame.id, "mealFrameName" => "own" },
                                                             ])
    expect(MealFramePatternEntry.exists?(bad_entry.id)).to be(true)
  end

  it "rolls back application of an existing malformed pattern" do
    MealFramePatternEntry.create!(meal_frame_pattern: pattern, meal_frame: foreign_frame, day_offset: 2, meal_type: 1)
    query = "mutation { applyMealFramePattern(input: {patternId: #{pattern.id}, startDate: \"2026-01-01\"}) { appliedMealFramePatternId } }"
    post("/graphql", params: { query: query }, as: :json, headers: headers)
    expect(response).to have_http_status(:not_found)
    expect(MealFrameEntry.count).to eq(0)
  end
end
