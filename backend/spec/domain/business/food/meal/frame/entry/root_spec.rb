require "rails_helper"

RSpec.describe Business::Food::Meal::Frame::Entry::Root do
  let(:params) { { user_id: "1", meal_frame_id: "2", date: "2026-11-02", meal_type: "3", meal_id: "7" } }
  let(:root) { described_class.new(**params) }

  describe "attributes" do
    it "coerces all six attributes" do
      expect(root.attributes).to eq("id" => nil, "user_id" => 1, "meal_frame_id" => 2,
                                    "date" => Date.new(2026, 11, 2), "meal_type" => 3, "meal_id" => 7)
    end

    %i[user_id meal_frame_id date meal_type].each do |required|
      it "validates #{required}" do
        expect { described_class.new(**params.except(required)) }.to raise_error(Business::Base::Values::InvalidAttributeError)
      end
    end
  end

  describe "#assign_meal" do
    it "assigns the meal" do
      root.assign_meal(8)
      expect(root.meal_id).to eq(8)
    end
  end

  describe "#set_id" do
    it "sets the initial id" do
      root.set_id(9)
      expect(root.id).to eq(9)
    end

    it "rejects changing an existing id" do
      root.set_id(9)
      expect { root.set_id(10) }.to raise_error("新規作成時以外idを変更できません")
    end
  end
end
