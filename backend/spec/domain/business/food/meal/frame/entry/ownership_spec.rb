require "rails_helper"

RSpec.describe "Frame entry assignment ownership" do
  let(:owner) { FactoryBot.create(:user, id_param: "entry-owner") }
  let(:actor) { FactoryBot.create(:user, id_param: "entry-actor") }
  let(:own_frame) { MealFrame.create!(user: actor, name: "own") }
  let(:foreign_frame) { MealFrame.create!(user: owner, name: "foreign") }
  let(:own_entry) { MealFrameEntry.create!(user: actor, meal_frame: own_frame, date: Date.today, meal_type: 1) }
  let(:foreign_entry) { MealFrameEntry.create!(user: owner, meal_frame: foreign_frame, date: Date.today, meal_type: 1) }
  let(:own_meal) { FactoryBot.create(:meal, user: actor, dish: FactoryBot.create(:dish, user: actor)) }
  let(:foreign_meal) { FactoryBot.create(:meal, user: owner, dish: FactoryBot.create(:dish, user: owner)) }

  [Business::Food::Meal::Frame::Entry, Business::Food::Meal::FrameEntry].each do |namespace|
    context namespace.name do
      let(:fill_command) { namespace::Usecase::FillWithMealCommand }

      it "rejects a foreign meal in an owned entry" do
        snapshot = own_entry.attributes
        expect {
          fill_command.call(user_id: actor.id, meal_frame_entry_id: own_entry.id, meal_id: foreign_meal.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
        expect(own_entry.reload.attributes).to eq(snapshot)
      end

      it "rejects a foreign entry even with an owned meal" do
        snapshot = foreign_entry.attributes
        expect {
          fill_command.call(user_id: actor.id, meal_frame_entry_id: foreign_entry.id, meal_id: own_meal.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
        expect(foreign_entry.reload.attributes).to eq(snapshot)
      end

      it "rejects an entry that references a foreign frame" do
        entry = MealFrameEntry.create!(user: actor, meal_frame: foreign_frame, date: Date.today, meal_type: 1)
        expect {
          fill_command.call(user_id: actor.id, meal_frame_entry_id: entry.id, meal_id: own_meal.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
        expect(entry.reload.meal_id).to be_nil
      end

      it "rejects a missing meal without filling the entry" do
        own_meal
        expect {
          fill_command.call(user_id: actor.id, meal_frame_entry_id: own_entry.id, meal_id: Meal.maximum(:id) + 1)
        }.to raise_error(ActiveRecord::RecordNotFound)
        expect(own_entry.reload.meal_id).to be_nil
      end

      it "rejects creating an entry for a foreign frame" do
        expect {
          namespace::Usecase::AddCommand.call(user_id: actor.id, meal_frame_id: foreign_frame.id, date: Date.today, meal_type: 1)
        }.to raise_error(ActiveRecord::RecordNotFound)
        expect(MealFrameEntry.count).to eq(0)
      end
    end
  end
end
