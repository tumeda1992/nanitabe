# frozen_string_literal: true

require "rails_helper"
require_relative "../../../../../support/factories/dish_repository"

module Business::Dish::Dish
  RSpec.describe Command::ReflectLatestNormalizeToDishNameCommand do
    describe ".call" do
      context "when call, " do
        let!(:dish_record) { find_or_create_dish() }
        let!(:normalize_word_record) { FactoryBot.create(:normalize_word_for_katsudon) }

        it "reflecting succeeds" do
          described_class.call

          normalized_dish_record = ::Dish.find(dish_record.id)
          expect(normalized_dish_record.name).to eq "かつ丼"
          expect(normalized_dish_record.normalized_name).to eq normalize_word_record.destination
        end
      end
    end
  end
end
