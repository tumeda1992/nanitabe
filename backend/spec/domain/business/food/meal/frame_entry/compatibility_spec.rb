require "rails_helper"

RSpec.describe "Legacy frame entry compatibility" do
  let(:legacy) { Business::Food::Meal::FrameEntry }
  let(:current) { Business::Food::Meal::Frame::Entry }
  let(:owner) { FactoryBot.create(:user, id_param: "compat-owner") }
  let(:other) { FactoryBot.create(:user, id_param: "compat-other") }
  let(:frame) { MealFrame.create!(user: owner, name: "互換枠") }
  let(:params) { { user_id: owner.id, meal_frame_id: frame.id, date: "2026-11-02", meal_type: 3 } }

  it "keeps legacy root identity, coercion and its public operations" do
    root = legacy::Root.new(**params, meal_id: "7")
    expect(root.class.name).to eq("Business::Food::Meal::FrameEntry::Root")
    expect(root.attributes).to eq("id" => nil, "user_id" => owner.id, "meal_frame_id" => frame.id,
                                  "date" => Date.new(2026, 11, 2), "meal_type" => 3, "meal_id" => 7)
    root.assign_meal(8)
    expect(root.meal_id).to eq(8)
    root.set_id(9)
    expect(root.id).to eq(9)
    expect { root.set_id(10) }.to raise_error("新規作成時以外idを変更できません")
    expect(root).not_to respond_to(:unassign_meal)
  end

  %i[user_id meal_frame_id date meal_type].each do |required|
    it "keeps the missing #{required} validation" do
      expect { legacy::Root.new(**params.except(required)) }.to raise_error(Business::Base::Values::InvalidAttributeError)
    end
  end

  it "persists exactly once and returns the legacy class with the saved attributes" do
    expect(MealFrameEntry).to receive(:persist_from_food_meal_frame_entry_root).once.and_call_original
    result = legacy::Usecase::AddCommand.call(**params)
    expect(result.class).to eq(legacy::Root)
    expect(MealFrameEntry.count).to eq(1)
    expect(MealFrameEntry.build_existing_root_from_id(result.id).attributes).to eq(result.attributes)
  end

  it "keeps direct Command construction private" do
    expect { legacy::Usecase::AddCommand.new(params) }.to raise_error(NoMethodError, /private method/)
  end

  it "rejects a foreign removal without modifying the record" do
    entry = MealFrameEntry.create!(**params)
    snapshot = entry.attributes
    expect {
      legacy::Usecase::RemoveCommand.call(user_id: other.id, meal_frame_entry_id: entry.id)
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect(entry.reload.attributes).to eq(snapshot)
  end

  it "keeps legacy fill returning the current root" do
    entry = MealFrameEntry.create!(**params)
    meal = FactoryBot.create(:meal, user: owner, dish: FactoryBot.create(:dish, user: owner))
    result = legacy::Usecase::FillWithMealCommand.call(user_id: owner.id, meal_frame_entry_id: entry.id, meal_id: meal.id)
    expect(result.class).to eq(current::Root)
    expect(entry.reload.meal_id).to eq(meal.id)
  end
end
