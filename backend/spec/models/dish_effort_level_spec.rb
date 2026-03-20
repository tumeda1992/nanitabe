require "rails_helper"

RSpec.describe DishEffortLevel, type: :model do
  describe "validations" do
    context "when all required attributes are present" do
      it "is valid" do
        effort_level = described_class.new(meal_position: 1, minutes: 10, label: "ぱぱっとできる")
        expect(effort_level).to be_valid
      end
    end

    context "when meal_position is absent" do
      it "is invalid" do
        effort_level = described_class.new(meal_position: nil, minutes: 10, label: "ぱぱっとできる")
        expect(effort_level).to be_invalid
        expect(effort_level.errors[:meal_position]).to be_present
      end
    end

    context "when minutes is absent" do
      it "is invalid" do
        effort_level = described_class.new(meal_position: 1, minutes: nil, label: "ぱぱっとできる")
        expect(effort_level).to be_invalid
        expect(effort_level.errors[:minutes]).to be_present
      end
    end

    context "when label is absent" do
      it "is invalid" do
        effort_level = described_class.new(meal_position: 1, minutes: 10, label: nil)
        expect(effort_level).to be_invalid
        expect(effort_level.errors[:label]).to be_present
      end
    end
  end

  describe ".for_meal_position" do
    before do
      described_class.create!(meal_position: 1, minutes: 50, label: "少し手間")
      described_class.create!(meal_position: 1, minutes: 10, label: "ぱぱっとできる")
      described_class.create!(meal_position: 1, minutes: 20, label: "普通")
      described_class.create!(meal_position: 2, minutes: 15, label: "メインのぱぱっと")
    end

    context "when meal_position is 1 (主食)" do
      it "returns only records for meal_position 1 ordered by minutes" do
        results = described_class.for_meal_position(1)

        expect(results.map(&:meal_position).uniq).to eq([1])
        expect(results.map(&:minutes)).to eq([10, 20, 50])
      end
    end

    context "when meal_position is 2 (メインディッシュ)" do
      it "returns only records for meal_position 2" do
        results = described_class.for_meal_position(2)

        expect(results.map(&:meal_position).uniq).to eq([2])
      end
    end

    context "when no records exist for the given meal_position" do
      it "returns empty" do
        results = described_class.for_meal_position(99)

        expect(results).to be_empty
      end
    end
  end
end
