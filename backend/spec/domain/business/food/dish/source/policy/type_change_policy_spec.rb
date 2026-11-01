require "rails_helper"

RSpec.describe Business::Food::Dish::Source::Policy::TypeChangePolicy do
  [
    [1, 1, false, true],
    [1, 1, true, true],
    [1, 3, false, true],
    [1, 3, true, false],
    [2, 3, true, false],
  ].each do |current, requested, related, allowed|
    it "returns #{allowed} for #{current} to #{requested} with related=#{related}" do
      expect(described_class.allowed?(current_type: current, requested_type: requested, has_related_dishes: related)).to be(allowed)
    end
  end
end
