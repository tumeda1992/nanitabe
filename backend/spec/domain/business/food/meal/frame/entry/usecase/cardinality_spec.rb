require "rails_helper"
require_relative "../../../../../../../support/factories/user_repository"
require_relative "../../../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Meal::Frame::Entry::Usecase::FillWithMealCommand do
  let(:user) { find_or_create_user }
  let(:meal) { FactoryBot.create(:meal, user: user, dish: FactoryBot.create(:dish, user: user)) }
  let(:frame) { MealFrame.create!(user: user, name: "計画") }
  let!(:first) { MealFrameEntry.create!(user: user, meal_frame: frame, date: meal.date, meal_type: meal.meal_type) }
  let!(:second) { MealFrameEntry.create!(user: user, meal_frame: frame, date: meal.date, meal_type: meal.meal_type) }

  def fill(entry)
    described_class.call(user_id: user.id, meal_frame_entry_id: entry.id, meal_id: meal.id)
  end

  it "rejects assignment to a different frame and preserves both entries" do
    fill(first)
    expect { fill(second) }.to raise_error(/既に.*枠/)
    expect(first.reload.meal_id).to eq(meal.id)
    expect(second.reload.meal_id).to be_nil
  end

  it "allows assigning the same meal to the same frame again" do
    fill(first)
    expect(fill(first).meal_id).to eq(meal.id)
    expect(MealFrameEntry.where(meal_id: meal.id).count).to eq(1)
  end

  it "allows multiple empty frames and reassignment after release" do
    expect(MealFrameEntry.where(meal_id: nil).count).to eq(2)
    fill(first)
    Business::Food::Meal::Frame::Entry::Usecase::UnassignMealCommand.call(user_id: user.id, meal_frame_entry_id: first.id)
    fill(second)
    expect(first.reload.meal_id).to be_nil
    expect(second.reload.meal_id).to eq(meal.id)
    meal.destroy!
    expect(second.reload.meal_id).to be_nil
  end

  it "enforces one frame even when bypassing commands and model validation" do
    first.update_columns(meal_id: meal.id)
    expect { second.update_columns(meal_id: meal.id) }.to raise_error(ActiveRecord::RecordNotUnique)
    expect(second.reload.meal_id).to be_nil
  end
end
