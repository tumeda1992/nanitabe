module Business::Food::Dish
  class Root < ::Business::Base::Entity
    attribute :id, :integer

    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :name, :dish_name
    validates :name, presence: true

    attribute :meal_position, :integer
    validates :meal_position, presence: true

    attribute :comment, :string
    validates :comment, presence: false

    attribute :source_id, :integer
    validates :source_id, presence: false

    attribute :source_locator, :any
    validates :source_locator, presence: false

    attribute :tags, :any, default: []
    validate :validate_tags, if: -> { tags.present? }

    # TODO: 破壊的変更には`!`をつける（そして、自身をreturnする）

    def set_id(new_id)
      raise "新規作成時以外idを変更できません" if id.present?

      self.id = new_id
    end

    def rename(new_name)
      raise "料理名は空にできません。" if new_name.blank?

      self.name = Name.initialize_and_normalize(new_name)
    end

    def renormalize_name
      self.name = Name.initialize_and_normalize(name.value)
    end

    def reposition_in_meal(new_meal_position)
      raise "料理の位置は空にできません。" if new_meal_position.blank?

      self.meal_position = new_meal_position
    end

    def revise_comment(new_comment)
      self.comment = new_comment
    end

    def attach_source(source, source_locator)
      raise "関連付けるレシピ元が指定されていません。" if source.blank?

      Policy::AttachSourcePolicy.ensure!(source, source_locator)

      self.source_id = source.id
      self.source_locator = source_locator
    end

    def detach_source
      self.source_id = nil
      self.source_locator = nil
    end

    def replace_tags(tags_for_replace)
      tags_for_replace.each_with_index do |tag, index|
        raise "タグ(#{index + 1})の型が不正です。" unless tag.is_a?(Business::Food::Dish::Tag::Root)

        tag.validate!
      end

      self.tags = tags_for_replace
    end

    private

    def validate_tags
      tags.each_with_index do |tag, index|
        next if tag.is_a?(Business::Food::Dish::Tag::Root) && tag.valid?

        errors.add(:tags, "タグ(#{index + 1})の内容が不正です。")
      end
    end
  end
end
