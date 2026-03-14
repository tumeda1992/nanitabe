module Business::Food::Dish::Tag::Usecase
  class AddTagToDishCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_id, :integer
    validates :dish_id, presence: true

    attribute :tag_content, :string
    validates :tag_content, presence: true

    def call
      dish_root = Business::Food::Dish::Factory.build_existing_from_id(dish_id)
      raise "指定した料理(id=#{dish_id})は存在しません。" if dish_root.blank?

      new_tag = Business::Food::Dish::Tag::Root.new(
        user_id: user_id,
        content: Business::Food::Dish::Tag::Content.initialize_and_normalize(tag_content),
      )
      dish_root.add_tag(new_tag)
      ::Dish.persist_from_food_dish_root(dish_root)
    end
  end
end
