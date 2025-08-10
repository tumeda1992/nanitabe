require "rails_helper"

RSpec.describe Business::Food::Dish::Root, type: :model do
  subject { Business::Food::Dish::Root.new(user_id: 1, name: "test", meal_position: 1) }

  describe "validations" do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:meal_position) }
  end
end
