module Business::Food::Dish::Source
  class Usecase::RemoveCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :source_id, :integer
    validates :source_id, presence: true

    def call
      source_record = ::DishSource.find_by(id: source_id, user_id: user_id)
      raise "指定したレシピ元は存在しません。" if source_record.blank?

      source_record.destroy!
    end
  end
end
