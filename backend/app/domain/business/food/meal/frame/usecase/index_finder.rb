module Business::Food::Meal::Frame
  class Usecase::IndexFinder < ::Business::Base::Finder
    attribute :user_id, :integer
    validates :user_id, presence: true

    def fetch
      ::MealFrame.where(user_id:).map do |record|
        Business::Food::Meal::Frame::Root.new(
          id: record.id,
          user_id: record.user_id,
          name: record.name,
        )
      end
    end
  end
end
