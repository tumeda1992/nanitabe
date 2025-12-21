require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../domain/business/dish/dish/evaluation/repository/repository_add_shared_examples"

module Mutations::Dish::Evaluation
  RSpec.describe EvaluateDish, type: :request do
    def build_mutation
      <<~GRAPHQL
        mutation evaluateDish(
          $dishId: Int!
          $score: Float!
        ) {
          evaluateDish(input: {
            dishId: $dishId
            score: $score
          }) {
            dishId
          }
        }
      GRAPHQL
    end

    before do
      comparer.build_records_for_test()
    end

    context "when evaluate source" do
      let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_EVALUATION_SHOULD_BE_CREATED] }

      it "evaluating succeeds" do
        variables = {
          dishId: comparer.prepared_records[:dish_record].id,
          score: comparer.values[:score],
        }
        fetch_mutation_with_auth(build_mutation, variables, comparer.prepared_records[:user_record].id)
        comparer.compare_to_expectation(self)
      end
    end
  end
end
