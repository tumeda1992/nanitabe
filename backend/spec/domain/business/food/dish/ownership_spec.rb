require "rails_helper"

RSpec.describe "Dish mutation ownership" do
  let(:owner) { FactoryBot.create(:user, id_param: "dish-owner") }
  let(:actor) { FactoryBot.create(:user, id_param: "dish-actor") }
  let!(:dish) { FactoryBot.create(:dish, user: owner) }
  let!(:source) { FactoryBot.create(:dish_source, user: owner) }

  it "rejects another user's dish update without changing its attributes" do
    snapshot = dish.attributes
    params = Business::Food::Dish::Usecase::Params::Dish.new(:update, id: dish.id, name: "changed")
    expect {
      Business::Food::Dish::Usecase::UpdateCommand.call(user_id: actor.id, dish_params: params)
    }.to raise_error("指定した料理は存在しません。")
    expect(dish.reload.attributes).to eq(snapshot)
  end

  it "rejects another user's source update without changing its attributes" do
    snapshot = source.attributes
    params = Business::Food::Dish::Source::Usecase::Params::Source.new(:update, id: source.id, name: "changed")
    expect {
      Business::Food::Dish::Source::Usecase::UpdateCommand.call(user_id: actor.id, source_params: params)
    }.to raise_error("指定したレシピ元は存在しません。")
    expect(source.reload.attributes).to eq(snapshot)
  end

  it "rolls back every tag when a bulk request mixes owned and foreign dishes" do
    own_dish = FactoryBot.create(:dish, user: actor)
    expect {
      Business::Food::Dish::Tag::Usecase::BulkAddTagToDishesCommand.call(
        user_id: actor.id, dish_ids: [own_dish.id, dish.id], tag_content: "new tag",
      )
    }.to raise_error("指定した料理(id=#{dish.id})は存在しません。")
    expect(DishTag.where(dish_id: [own_dish.id, dish.id])).to be_empty
  end
end
