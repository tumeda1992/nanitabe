require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"

RSpec.describe "Releasing the original frame when a meal moves" do
  let(:user) { find_or_create_user }
  let(:dish) { FactoryBot.create(:dish, user: user) }
  let(:date) { Date.new(2026, 10, 10) }
  let!(:meal) { FactoryBot.create(:meal, user: user, dish: dish, date: date, meal_type: 1) }
  let(:frame) { MealFrame.create!(user: user, name: "朝の計画") }
  let!(:entry) { MealFrameEntry.create!(user: user, meal_frame: frame, meal: meal, date: date, meal_type: 1) }

  [:current, :legacy].each do |path|
    context "through #{path}" do
      def update_meal(path, changes)
        if path == :current
          attributes = { id: meal.id, dish_id: meal.dish_id, date: meal.date, meal_type: meal.meal_type }.merge(changes)
          params = Business::Food::Meal::Usecase::Params::Meal.new(:update, **attributes)
          Business::Food::Meal::Usecase::UpdateCommand.call(user_id: user.id, meal_params: params)
        else
          value = Business::Dish::Meal::Repository.find(meal.id)
          value.assign_attributes(**changes)
          Business::Dish::Meal::Repository.update(value, user.id)
        end
      end

      [{ date: Date.new(2026, 10, 11) }, { meal_type: 2 }].each do |changes|
        it "releases the frame for #{changes.keys.first} without moving the frame" do
          update_meal(path, changes)
          expect(entry.reload.meal_id).to be_nil
          expect(entry.date).to eq(date)
          expect(entry.meal_type).to eq(1)
          changes.each { |key, value| expect(meal.reload.public_send(key)).to eq(value) }
        end
      end

      it "keeps the frame for comment, dish, and unchanged schedule updates" do
        new_dish = FactoryBot.create(:dish, user: user)
        result = update_meal(path, date: date, meal_type: 1, comment: "更新", dish_id: new_dish.id)
        expect(entry.reload.meal_id).to eq(meal.id)
        expect(meal.reload.dish_id).to eq(new_dish.id)
        expect(result).to eq(true) if path == :legacy
      end

      it "rolls the meal back when releasing its frame fails" do
        relation = double("frame entries")
        allow(MealFrameEntry).to receive(:where).and_call_original
        allow(MealFrameEntry).to receive(:where).with(meal_id: meal.id).and_return(relation)
        allow(relation).to receive(:update_all).and_raise("release failed")
        expect { update_meal(path, date: date + 1) }.to raise_error("release failed")
        expect(meal.reload.date).to eq(date)
        expect(entry.reload.meal_id).to eq(meal.id)
      end

      it "returns the empty original frame and moved meal without a frame in the finder" do
        update_meal(path, date: date + 1)
        days = Business::Food::Meal::Usecase::DateMealsFinder.call(access_user_id: user.id, start_date: date, last_date: date + 1)
        expect(days[0][:date]).to eq(date)
        expect(days[0][:meals]).to be_empty
        expect(days[0][:frame_entries].pluck(:id)).to eq([entry.id])
        expect(days[1][:meals].first[:id]).to eq(meal.id)
        expect(days[1][:meals].first[:meal_frame_entry_id]).to be_nil
      end

      it "releases both frames on a swap and leaves each frame's schedule unchanged" do
        other = FactoryBot.create(:meal, user: user, dish: dish, date: date + 1, meal_type: 2)
        other_entry = MealFrameEntry.create!(user: user, meal_frame: frame, meal: other, date: date + 1, meal_type: 2)
        swap = path == :current ? Business::Food::Meal::Usecase::SwapMealsBetweenDaysCommand : Business::Dish::Meal::Command::SwapMealsBetweenDaysCommand
        swap.call(user_id: user.id, date1: date, date2: date + 1)
        expect(meal.reload.date).to eq(date + 1)
        expect(other.reload.date).to eq(date)
        expect([entry.reload.meal_id, other_entry.reload.meal_id]).to eq([nil, nil])
        expect([entry.date, entry.meal_type, other_entry.date, other_entry.meal_type]).to eq([date, 1, date + 1, 2])
      end

      it "rolls earlier meal saves and releases back when a later swap save fails" do
        other = FactoryBot.create(:meal, user: user, dish: dish, date: date + 1)
        allow_any_instance_of(Meal).to receive(:save!).and_wrap_original do |original, *args|
          raise "second save failed" if original.receiver.id == other.id

          original.call(*args)
        end
        swap = path == :current ? Business::Food::Meal::Usecase::SwapMealsBetweenDaysCommand : Business::Dish::Meal::Command::SwapMealsBetweenDaysCommand
        expect { swap.call(user_id: user.id, date1: date, date2: date + 1) }.to raise_error("second save failed")
        expect(meal.reload.date).to eq(date)
        expect(other.reload.date).to eq(date + 1)
        expect(entry.reload.meal_id).to eq(meal.id)
      end
    end
  end
end
