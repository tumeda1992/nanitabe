require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"

RSpec.describe "mealsForCalender query - frameEntries", type: :request do
  let!(:user_record) { find_or_create_user }

  def build_query
    <<~GRAPHQL
      query mealsForCalender($startDate: ISO8601Date!, $lastDate: ISO8601Date!) {
        mealsForCalender(startDate: $startDate, lastDate: $lastDate) {
          date
          meals {
            id
          }
          frameEntries {
            id
            mealFrameId
            mealFrameName
            mealType
          }
        }
      }
    GRAPHQL
  end

  let(:target_date) { Date.new(2026, 3, 1) }
  let(:variables) { { startDate: target_date.iso8601, lastDate: target_date.iso8601 } }

  context "when user has frame entries on the date" do
    let!(:meal_frame) { MealFrame.create!(user: user_record, name: "週末枠") }
    let!(:frame_entry) do
      MealFrameEntry.create!(
        user: user_record,
        meal_frame: meal_frame,
        date: target_date,
        meal_type: 3,
      )
    end

    it "returns frameEntries in the response" do
      data = fetch_mutation_with_auth(build_query, variables, user_record.id)

      date_meals = data["mealsForCalender"].find { |d| d["date"] == target_date.iso8601 }
      expect(date_meals).not_to be_nil

      frame_entries = date_meals["frameEntries"]
      expect(frame_entries.length).to eq(1)
      expect(frame_entries[0]["id"]).to eq(frame_entry.id)
      expect(frame_entries[0]["mealFrameId"]).to eq(meal_frame.id)
      expect(frame_entries[0]["mealFrameName"]).to eq("週末枠")
      expect(frame_entries[0]["mealType"]).to eq(3)
    end
  end

  context "when user has no frame entries" do
    it "returns empty frameEntries array" do
      data = fetch_mutation_with_auth(build_query, variables, user_record.id)

      date_results = data["mealsForCalender"]
      date_results.each do |date_result|
        expect(date_result["frameEntries"]).to eq([])
      end
    end
  end
end
