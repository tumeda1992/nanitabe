require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Meal::DateMealsFinder do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }
  let(:dish_record2) { find_or_create_dish }
  let(:dish_source) { create(:dish_source, name: "テストレシピ本", type: "RecipeBook", user_id: user_record.id) }
  let(:evaluation_score) { 4 }
  let(:start_date) { Date.today - 7.days }
  let(:last_date) { Date.today }

  before do
    # テスト用のデータを作成
    dish_evaluation = create(:dish_evaluation, dish_id: dish_record.id, score: evaluation_score)
    dish_source_relation = create(:dish_source_relation,
                                  dish_id: dish_record.id,
                                  dish_source_id: dish_source.id,
                                  recipe_book_page: 42,
                                  recipe_website_url: nil,
                                  recipe_source_memo: "テストメモ")
    tag1 = create(:dish_tag, dish_id: dish_record.id, name: "テストタグ1")
    tag2 = create(:dish_tag, dish_id: dish_record.id, name: "テストタグ2")

    # 範囲内の食事
    @meal1 = create(:meal, user_id: user_record.id, dish_id: dish_record.id, date: start_date + 1.day, meal_type: 1, comment: "テスト食事1")
    @meal2 = create(:meal, user_id: user_record.id, dish_id: dish_record2.id, date: last_date - 1.day, meal_type: 2, comment: "テスト食事2")

    # 範囲外の食事
    @outside_meal = create(:meal, user_id: user_record.id, dish_id: dish_record.id, date: start_date - 1.day, meal_type: 1, comment: "範囲外の食事")
  end

  describe "#fetch" do
    context "正常なパラメータの場合" do
      it "指定された日付範囲内の食事を日付ごとに取得する" do
        finder = described_class.new(
          access_user_id: user_record.id,
          start_date: start_date,
          last_date: last_date
        )

        result = finder.fetch

        # 結果は日付ごとにグループ化されている
        expect(result).to be_an(Array)
        expect(result.size).to be >= 2 # 少なくとも2つの日付のグループが存在する

        # 日付がキーとして存在することを確認
        dates = result.map { |item| item[:date] }
        expect(dates).to include(@meal1.date)
        expect(dates).to include(@meal2.date)

        # 範囲外の食事は含まれないことを確認
        expect(dates).not_to include(@outside_meal.date)

        # 食事データの内容を確認
        meal1_data = nil
        result.each do |date_group|
          date_group[:meals].each do |meal|
            if meal[:id] == @meal1.id
              meal1_data = meal
              break
            end
          end
        end

        expect(meal1_data).not_to be_nil
        expect(meal1_data[:dish]).to be_present
        expect(meal1_data[:dish][:evaluation_score]).to eq(evaluation_score)
        expect(meal1_data[:dish][:dish_source_relation]).to be_present
        expect(meal1_data[:dish][:dish_source_relation][:source_name]).to eq(dish_source.name)
        expect(meal1_data[:dish][:dish_source_relation][:type]).to eq(dish_source.type)
        expect(meal1_data[:dish][:tags].size).to eq(2)
      end
    end

    context "ユーザーIDが異なる場合" do
      it "他のユーザーの食事は取得されない" do
        other_user = create(:user)
        create(:meal, user_id: other_user.id, dish_id: dish_record.id, date: start_date + 1.day)

        finder = described_class.new(
          access_user_id: user_record.id,
          start_date: start_date,
          last_date: last_date
        )

        result = finder.fetch
        user_ids = result.flat_map { |date_group| date_group[:meals].map { |meal| meal[:user_id] } }.uniq

        expect(user_ids).to contain_exactly(user_record.id)
        expect(user_ids).not_to include(other_user.id)
      end
    end

    context "バリデーションエラーの場合" do
      it "access_user_idが空の場合はエラーになる" do
        finder = described_class.new(
          start_date: start_date,
          last_date: last_date
        )

        expect(finder.valid?).to be false
        expect(finder.errors[:access_user_id]).to include("can't be blank")
      end

      it "start_dateが空の場合はエラーになる" do
        finder = described_class.new(
          access_user_id: user_record.id,
          last_date: last_date
        )

        expect(finder.valid?).to be false
        expect(finder.errors[:start_date]).to include("can't be blank")
      end

      it "last_dateが空の場合はエラーになる" do
        finder = described_class.new(
          access_user_id: user_record.id,
          start_date: start_date
        )

        expect(finder.valid?).to be false
        expect(finder.errors[:last_date]).to include("can't be blank")
      end
    end
  end
end
