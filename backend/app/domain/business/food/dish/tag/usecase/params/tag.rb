module Business::Food::Dish::Tag
  class Usecase::Params::Tag < ::Business::Base::CommandParams
    attribute :id, :integer

    attribute :content, :string
    validates :content, presence: true

    attribute :normalized_content, :string
    validates :normalized_content, presence: false

    def to_root(user_id)
      Root.new(
        id:,
        user_id:,
        content: Content.initialize_with_normalizing_if_need(content, normalized_content)
      )
    end
  end
end
