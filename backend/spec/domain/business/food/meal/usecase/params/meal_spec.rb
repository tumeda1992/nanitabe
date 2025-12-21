require "rails_helper"

RSpec.describe Business::Food::Meal::Usecase::Params::Meal do
  let(:valid_create_attributes) do
    {
      dish_id: 1,
      date: Date.today,
      meal_type: 1,
      comment: "test comment"
    }
  end

  let(:valid_update_attributes) do
    {
      id: 123,
      dish_id: 1,
      date: Date.today,
      meal_type: 1,
      comment: "test comment"
    }
  end

  describe "validations for create" do
    it "is valid with valid attributes" do
      params = described_class.new(:create, **valid_create_attributes)
      expect(params.valid_for_create?).to be true
    end

    it "allows blank comment" do
      params = described_class.new(:create, **valid_create_attributes.except(:comment))
      expect(params.valid_for_create?).to be true
    end

    it "requires dish_id" do
      expect {
        described_class.new(:create, **valid_create_attributes.except(:dish_id))
      }.to raise_error(Business::Base::Values::InvalidAttributeError, /Dish can't be blank/)
    end

    it "requires date" do
      expect {
        described_class.new(:create, **valid_create_attributes.except(:date))
      }.to raise_error(Business::Base::Values::InvalidAttributeError, /Date can't be blank/)
    end

    it "requires meal_type" do
      expect {
        described_class.new(:create, **valid_create_attributes.except(:meal_type))
      }.to raise_error(Business::Base::Values::InvalidAttributeError, /Meal type can't be blank/)
    end

    it "rejects presence of id" do
      expect {
        described_class.new(:create, **valid_create_attributes.merge(id: 123))
      }.to raise_error(Business::Base::Values::InvalidAttributeError, /Id must be blank/)
    end
  end

  describe "validations for update" do
    it "is valid with valid attributes including id" do
      params = described_class.new(:update, **valid_update_attributes)
      expect(params.valid_for_update?).to be true
    end

    it "requires id" do
      expect {
        described_class.new(:update, **valid_create_attributes)
      }.to raise_error(Business::Base::Values::InvalidAttributeError, /Id can't be blank/)
    end

    it "requires dish_id" do
      expect {
        described_class.new(:update, **valid_update_attributes.except(:dish_id))
      }.to raise_error(Business::Base::Values::InvalidAttributeError, /Dish can't be blank/)
    end

    it "requires date" do
      expect {
        described_class.new(:update, **valid_update_attributes.except(:date))
      }.to raise_error(Business::Base::Values::InvalidAttributeError, /Date can't be blank/)
    end

    it "requires meal_type" do
      expect {
        described_class.new(:update, **valid_update_attributes.except(:meal_type))
      }.to raise_error(Business::Base::Values::InvalidAttributeError, /Meal type can't be blank/)
    end
  end

  describe "#valid_for_create?" do
    it "validates with create context" do
      params = described_class.new(:create, **valid_create_attributes)
      expect(params.valid_for_create?).to be true
    end
  end

  describe "#valid_for_update?" do
    it "validates with update context" do
      params = described_class.new(:update, **valid_update_attributes)
      expect(params.valid_for_update?).to be true
    end
  end
end
