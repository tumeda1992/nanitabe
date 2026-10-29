require "rails_helper"
require_relative "graphql_auth_helper"

RSpec.describe "GraphQL authentication helper", type: :request do
  let!(:user_a) { User.create!(id_param: "auth-helper-user-a") }
  let!(:user_b) { User.create!(id_param: "auth-helper-user-b") }
  let!(:frame_a) { MealFrame.create!(user: user_a, name: "Aの枠") }
  let!(:frame_b) { MealFrame.create!(user: user_b, name: "Bの枠") }

  let(:query) { "query { mealFrames { id name } }" }

  it "authenticates repeated requests for the same user" do
    2.times do
      data = fetch_mutation_with_auth(query, {}, user_a.id)
      expect(data.fetch("mealFrames").map { |frame| frame.fetch("id") }).to eq([frame_a.id])
    end
  end

  it "keeps different users separate across repeated requests" do
    [user_a, user_b, user_a, user_b].each do |user|
      data = fetch_mutation_with_auth(query, {}, user.id)
      expected_frame = user == user_a ? frame_a : frame_b
      expect(data.fetch("mealFrames").map { |frame| frame.fetch("id") }).to eq([expected_frame.id])
    end
  end
end
