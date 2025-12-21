module Business::Dish::Dish::Tag
  class Command::UpdateTagsCommand < ::Business::Base::Command
    attribute :dish_id, :integer
    validates :dish_id, presence: true

    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_tags, :command_params_array
    validates :dish_tags, disallow_nil: true

    # やってることはほぼdelete insertだが、変更がないのにdelete insertをしたくないためこの作りへ
    def call
      existing_dish_tags = Repository.fetch_tags_of_dish(dish_id)

      update_tags_if_need

      dish_tag_ids = dish_tags.map(&:id)
      existing_dish_tag_ids = existing_dish_tags.map(&:id)

      return if dish_tag_ids == existing_dish_tag_ids

      add_tags_if_need(dish_tags, dish_id, user_id)
      delete_tags_if_need(existing_dish_tag_ids, dish_tag_ids)
    end

    def add_tags_if_need(dish_tags, dish_id, user_id)
      dish_tags
        .select { |tag| tag.id.blank?}
        .map do |tag|
          Tag.new(
            user_id:,
            dish_id:,
            content: tag.content,
            normalized_content: Business::Dish::Word::Normalize::Command::NormalizeCommand.call(
              string_sequence: tag.content
            ),
          )
        end.map do |tag|
          Repository.add(tag)
        end
    end

    def update_tags_if_need
      # TODO: 実装時にロジック記載
    end

    def delete_tags_if_need(existing_dish_tag_ids, dish_tag_ids)
      existing_dish_tag_ids
        .reject {|existing_dish_tag_id| dish_tag_ids.include?(existing_dish_tag_id)}
        .each do |tag_id_needing_removed|
          Repository.remove(tag_id_needing_removed)
        end
    end
  end
end
