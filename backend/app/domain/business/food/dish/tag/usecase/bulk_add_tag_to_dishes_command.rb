module Business::Food::Dish::Tag::Usecase
  class BulkAddTagToDishesCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_ids, :any
    validates :dish_ids, presence: true

    attribute :tag_content, :string
    validates :tag_content, presence: true

    def call
      ActiveRecord::Base.transaction do
        dish_ids.each do |dish_id|
          AddTagToDishCommand.call(
            user_id: user_id,
            dish_id: dish_id,
            tag_content: tag_content,
          )
        end
      end
    end
  end
end
