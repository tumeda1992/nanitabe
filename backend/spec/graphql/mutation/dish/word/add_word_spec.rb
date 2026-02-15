require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"

module Mutations::Dish::Word
  RSpec.describe AddWord, type: :request do
    let(:user) { find_or_create_user }

    before do
      # Clean up test data to avoid conflicts with ReflectLatestNormalizeWordCommand
      NormalizeWord.delete_all
      Dish.delete_all
    end

    def build_mutation
      <<~GRAPHQL
        mutation addDishWord($word: WordForCreate!) {
          addDishWord(input: {word: $word}) {
            normalizeWordId
          }
        }
      GRAPHQL
    end

    context "when source only" do
      it "creates normalize_word with normalized destination equals to normalized source" do
        variables = { word: { source: "ぎょうざ" } }
        result = fetch_mutation_with_auth(build_mutation, variables, user.id)

        expect(result["addDishWord"]["normalizeWordId"]).to be_present
        word = NormalizeWord.find(result["addDishWord"]["normalizeWordId"])
        expect(word.entered_source).to eq("ぎょうざ")
        expect(word.entered_destination).to eq("")
        expect(word.destination).to eq(word.source)
      end
    end

    context "when source and destination" do
      it "creates normalize_word" do
        variables = { word: { source: "ぎょうざ", destination: "餃子" } }
        result = fetch_mutation_with_auth(build_mutation, variables, user.id)

        word = NormalizeWord.find(result["addDishWord"]["normalizeWordId"])
        expect(word.entered_source).to eq("ぎょうざ")
        expect(word.entered_destination).to eq("餃子")
      end
    end

    context "when source is blank" do
      it "returns validation error", pending: "Validation error handling needs GraphQL error format" do
        variables = { word: { source: "" } }
        expect {
          fetch_mutation_with_auth(build_mutation, variables, user.id)
        }.to raise_error(/Source can't be blank/)
      end
    end
  end
end
