require "rails_helper"

RSpec.describe "Review backend GraphQL readiness", type: :request do
  it "responds to the unauthenticated metadata query without business-record writes" do
    before = [User.count, Dish.count, Meal.count]
    post "/graphql", params: { query: "query ReviewBackendReadiness { __typename }" }, as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body).to eq("data" => { "__typename" => "Query" })
    expect([User.count, Dish.count, Meal.count]).to eq(before)
  end
end
