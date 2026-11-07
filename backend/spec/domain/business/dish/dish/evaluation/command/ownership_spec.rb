require "rails_helper"

RSpec.describe Business::Dish::Dish::Evaluation::Command::EvaluateCommand do
  let(:owner) { FactoryBot.create(:user, id_param: "evaluation-owner") }
  let(:actor) { FactoryBot.create(:user, id_param: "evaluation-actor") }
  let!(:dish) { FactoryBot.create(:dish, user: owner) }

  it "rejects the first evaluation of a foreign dish" do
    expect {
      described_class.call(user_id: actor.id, dish_id: dish.id, score: 4.0)
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect(DishEvaluation.exists?(dish_id: dish.id)).to be(false)
  end

  it "rejects updating a foreign dish even if its old evaluation names the actor" do
    evaluation = FactoryBot.create(:dish_evaluation, dish: dish, user: actor, score: 2.0)
    snapshot = evaluation.attributes
    expect {
      described_class.call(user_id: actor.id, dish_id: dish.id, score: 4.0)
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect(evaluation.reload.attributes).to eq(snapshot)
  end

  it "lets the dish owner replace an inconsistent evaluation and repairs its owner" do
    evaluation = FactoryBot.create(:dish_evaluation, dish: dish, user: actor, score: 2.0)
    result = described_class.call(user_id: owner.id, dish_id: dish.id, score: 4.0)
    expect(result.user_id).to eq(owner.id)
    expect(evaluation.reload.user_id).to eq(owner.id)
    expect(evaluation.score).to eq(4.0)
  end

  it "rejects an absent dish without creating an evaluation" do
    expect {
      described_class.call(user_id: actor.id, dish_id: Dish.maximum(:id) + 1, score: 4.0)
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect(DishEvaluation.count).to eq(0)
  end
end
