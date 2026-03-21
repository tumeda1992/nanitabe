require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"

RSpec.describe "mealFrames query", type: :request do
  let!(:user_record) { find_or_create_user }

  def build_query
    <<~GRAPHQL
      query mealFrames {
        mealFrames {
          id
          name
        }
      }
    GRAPHQL
  end

  context "when user has meal frames" do
    let!(:frame1) { MealFrame.create!(user: user_record, name: "週末枠") }
    let!(:frame2) { MealFrame.create!(user: user_record, name: "平日枠") }

    it "returns all meal frames for the user" do
      data = fetch_mutation_with_auth(build_query, {}, user_record.id)

      frames = data["mealFrames"]
      expect(frames.length).to eq(2)

      names = frames.map { |f| f["name"] }
      expect(names).to include("週末枠", "平日枠")
    end
  end

  context "when user has no meal frames" do
    it "returns empty array" do
      data = fetch_mutation_with_auth(build_query, {}, user_record.id)

      expect(data["mealFrames"]).to eq([])
    end
  end
end
