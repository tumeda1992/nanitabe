require "rails_helper"

RSpec.describe "Meal frame mutation ownership" do
  let(:owner) { FactoryBot.create(:user, id_param: "frame-owner") }
  let(:actor) { FactoryBot.create(:user, id_param: "frame-actor") }
  let!(:frame) { MealFrame.create!(user: owner, name: "original") }

  it "rejects renaming another user's frame" do
    expect {
      Business::Food::Meal::Frame::Usecase::UpdateCommand.call(user_id: actor.id, meal_frame_id: frame.id, name: "changed")
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect(frame.reload.name).to eq("original")
  end

  it "rejects deleting another user's unused frame" do
    expect {
      Business::Food::Meal::Frame::Usecase::RemoveCommand.call(user_id: actor.id, meal_frame_id: frame.id)
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect(MealFrame.exists?(frame.id)).to be(true)
  end

  it "checks ownership before disclosing that a foreign frame is in use" do
    entry = MealFrameEntry.create!(user: owner, meal_frame: frame, date: Date.today, meal_type: 1)
    expect {
      Business::Food::Meal::Frame::Usecase::RemoveCommand.call(user_id: actor.id, meal_frame_id: frame.id)
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect(MealFrameEntry.exists?(entry.id)).to be(true)
  end

  it "rejects deleting another user's frame entry" do
    entry = MealFrameEntry.create!(user: owner, meal_frame: frame, date: Date.today, meal_type: 1)
    snapshot = entry.attributes
    expect {
      Business::Food::Meal::Frame::Entry::Usecase::RemoveCommand.call(user_id: actor.id, meal_frame_entry_id: entry.id)
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect(entry.reload.attributes).to eq(snapshot)
  end
end
