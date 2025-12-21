require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Meal::Usecase::SwapMealsBetweenDaysCommand do
  let(:user_record) { find_or_create_user }
  let(:dish1_record) { find_or_create_dish }
  let(:dish2_record) { FactoryBot.create(:dish, user: user_record) }
  let(:dish3_record) { FactoryBot.create(:dish, user: user_record) }

  let(:date1) { Date.parse("2023-01-01") }
  let(:date2) { Date.parse("2023-01-02") }

  describe "validations" do
    context "when user_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(
            date1: date1,
            date2: date2
          )
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when date1 is missing" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            date2: date2
          )
        }.to raise_error(/Date1 can't be blank/)
      end
    end

    context "when date2 is missing" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            date1: date1
          )
        }.to raise_error(/Date2 can't be blank/)
      end
    end

    context "when user_id is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: nil,
            date1: date1,
            date2: date2
          )
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when date1 is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            date1: nil,
            date2: date2
          )
        }.to raise_error(/Date1 can't be blank/)
      end
    end

    context "when date2 is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            date1: date1,
            date2: nil
          )
        }.to raise_error(/Date2 can't be blank/)
      end
    end
  end

  describe "#call" do
    context "with meals on both dates" do
      let!(:date1_meal1) do
        FactoryBot.create(
          :meal,
          user: user_record,
          dish: dish1_record,
          date: date1,
          meal_type: 1,
          comment: "date1 meal1"
        )
      end
      let!(:date1_meal2) do
        FactoryBot.create(
          :meal,
          user: user_record,
          dish: dish2_record,
          date: date1,
          meal_type: 2,
          comment: "date1 meal2"
        )
      end
      let!(:date2_meal1) do
        FactoryBot.create(
          :meal,
          user: user_record,
          dish: dish3_record,
          date: date2,
          meal_type: 1,
          comment: "date2 meal1"
        )
      end

      it "swaps meals between the two dates" do
        result = described_class.call(
          user_id: user_record.id,
          date1: date1,
          date2: date2
        )

        expect(result).to be_an(Array)
        expect(result.length).to eq(3)

        # Check that all meals have been moved to the opposite dates
        expect(Meal.where(date: date1).count).to eq(1)
        expect(Meal.where(date: date2).count).to eq(2)

        # Verify specific meal movements
        moved_date2_meal = Meal.find(date2_meal1.id)
        expect(moved_date2_meal.date).to eq(date1)

        moved_date1_meals = Meal.where(id: [date1_meal1.id, date1_meal2.id])
        moved_date1_meals.each do |meal|
          expect(meal.date).to eq(date2)
        end
      end

      it "preserves all meal attributes except date" do
        described_class.call(
          user_id: user_record.id,
          date1: date1,
          date2: date2
        )

        all_meals = Meal.where(id: [date1_meal1.id, date1_meal2.id, date2_meal1.id])

        moved_meal1 = all_meals.find(date1_meal1.id)
        expect(moved_meal1.meal_type).to eq(1)
        expect(moved_meal1.comment).to eq("date1 meal1")
        expect(moved_meal1.dish_id).to eq(dish1_record.id)
        expect(moved_meal1.user_id).to eq(user_record.id)
        expect(moved_meal1.date).to eq(date2)

        moved_meal2 = all_meals.find(date1_meal2.id)
        expect(moved_meal2.meal_type).to eq(2)
        expect(moved_meal2.comment).to eq("date1 meal2")
        expect(moved_meal2.dish_id).to eq(dish2_record.id)
        expect(moved_meal2.user_id).to eq(user_record.id)
        expect(moved_meal2.date).to eq(date2)

        moved_meal3 = all_meals.find(date2_meal1.id)
        expect(moved_meal3.meal_type).to eq(1)
        expect(moved_meal3.comment).to eq("date2 meal1")
        expect(moved_meal3.dish_id).to eq(dish3_record.id)
        expect(moved_meal3.user_id).to eq(user_record.id)
        expect(moved_meal3.date).to eq(date1)
      end
    end

    context "with meals only on date1" do
      let!(:date1_meal) do
        FactoryBot.create(
          :meal,
          user: user_record,
          dish: dish1_record,
          date: date1,
          meal_type: 1,
          comment: "only date1 meal"
        )
      end

      it "moves date1 meals to date2" do
        result = described_class.call(
          user_id: user_record.id,
          date1: date1,
          date2: date2
        )

        expect(result.length).to eq(1)

        expect(Meal.where(date: date1).count).to eq(0)
        expect(Meal.where(date: date2).count).to eq(1)

        moved_meal = Meal.where(date: date2).first
        expect(moved_meal.dish_id).to eq(dish1_record.id)
        expect(moved_meal.comment).to eq("only date1 meal")
        expect(moved_meal.meal_type).to eq(1)
        expect(moved_meal.user_id).to eq(user_record.id)
      end
    end

    context "with meals only on date2" do
      let!(:date2_meal) do
        FactoryBot.create(
          :meal,
          user: user_record,
          dish: dish1_record,
          date: date2,
          meal_type: 1,
          comment: "only date2 meal"
        )
      end

      it "moves date2 meals to date1" do
        result = described_class.call(
          user_id: user_record.id,
          date1: date1,
          date2: date2
        )

        expect(result.length).to eq(1)

        expect(Meal.where(date: date1).count).to eq(1)
        expect(Meal.where(date: date2).count).to eq(0)

        moved_meal = Meal.where(date: date1).first
        expect(moved_meal.dish_id).to eq(dish1_record.id)
        expect(moved_meal.comment).to eq("only date2 meal")
        expect(moved_meal.meal_type).to eq(1)
        expect(moved_meal.user_id).to eq(user_record.id)
      end
    end

    context "with no meals on either date" do
      it "returns empty array" do
        result = described_class.call(
          user_id: user_record.id,
          date1: date1,
          date2: date2
        )

        expect(result).to eq([])
        expect(Meal.where(date: date1).count).to eq(0)
        expect(Meal.where(date: date2).count).to eq(0)
      end
    end

    context "with same date for both parameters" do
      let!(:same_date_meal) do
        FactoryBot.create(
          :meal,
          user: user_record,
          dish: dish1_record,
          date: date1,
          meal_type: 1,
          comment: "same date meal"
        )
      end

      it "does not change anything when swapping same date" do
        original_count = Meal.where(date: date1).count

        result = described_class.call(
          user_id: user_record.id,
          date1: date1,
          date2: date1
        )

        expect(result.length).to eq(2) # same meal appears twice in result
        expect(Meal.where(date: date1).count).to eq(original_count)

        meal = Meal.find(same_date_meal.id)
        expect(meal.date).to eq(date1)
        expect(meal.comment).to eq("same date meal")
      end
    end
  end
end
