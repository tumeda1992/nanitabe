require 'rails_helper'

RSpec.describe 'Admin::Food::Dish::Word::NormalizeWords', type: :system do
  before do
    driven_by(:rack_test)
  end

  describe '一覧表示' do
    it '既存のNormalizeWordが一覧に表示される' do
      word1 = NormalizeWord.create!(entered_source: 'test1', entered_destination: '', source: 'test1', destination: 'test1')
      word2 = NormalizeWord.create!(entered_source: 'test2', entered_destination: '', source: 'test2', destination: 'test2')

      visit admin_food_dish_word_normalize_words_path

      expect(page).to have_content('正規化ワード管理')
      expect(page).to have_content('test1')
      expect(page).to have_content('test2')
    end

    it '「新規作成」リンクが表示される' do
      visit admin_food_dish_word_normalize_words_path

      expect(page).to have_link('新規作成', href: new_admin_food_dish_word_normalize_word_path)
    end
  end

  describe '新規作成フロー' do
    it '「新規作成」→ 入力 → 作成 → 一覧に表示' do
      visit admin_food_dish_word_normalize_words_path
      click_link '新規作成'

      expect(page).to have_current_path(new_admin_food_dish_word_normalize_word_path)

      fill_in 'source', with: 'new_test'
      fill_in 'destination', with: 'new_dest'
      click_button '作成'

      expect(page).to have_current_path(admin_food_dish_word_normalize_words_path)
      expect(page).to have_content('正規化ワードを作成しました')
      expect(page).to have_content('new_test')
    end
  end

  describe '編集フロー' do
    it '「編集」→ 変更 → 更新 → 一覧に反映' do
      word = NormalizeWord.create!(entered_source: 'old_test', entered_destination: '', source: 'old_test', destination: 'old_test')

      visit admin_food_dish_word_normalize_words_path
      click_link '編集'

      expect(page).to have_current_path(edit_admin_food_dish_word_normalize_word_path(word))

      fill_in 'source', with: 'updated_test'
      fill_in 'destination', with: 'updated_dest'
      click_button '更新'

      expect(page).to have_current_path(admin_food_dish_word_normalize_words_path)
      expect(page).to have_content('正規化ワードを更新しました')
      expect(page).to have_content('updated_test')
    end
  end

  describe '削除フロー' do
    it '「削除」→ 確認 → 一覧から削除' do
      word = NormalizeWord.create!(entered_source: 'delete_test', entered_destination: '', source: 'delete_test', destination: 'delete_test')

      visit admin_food_dish_word_normalize_words_path
      expect(page).to have_content('delete_test')

      # rack_testでは確認ダイアログは無視される
      click_button '削除'

      expect(page).to have_current_path(admin_food_dish_word_normalize_words_path)
      expect(page).to have_content('正規化ワードを削除しました')
      expect(page).not_to have_content('delete_test')
    end
  end
end
