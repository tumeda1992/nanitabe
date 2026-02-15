require 'rails_helper'

RSpec.describe 'Admin::Food::Dish::Word::NormalizeWords', type: :request do
  describe 'GET /admin/food/dish/word/normalize_words' do
    it 'returns http success' do
      get admin_food_dish_word_normalize_words_path
      expect(response).to have_http_status(:success)
    end

    it 'displays all NormalizeWord records' do
      word1 = NormalizeWord.create!(entered_source: 'test1', entered_destination: '', source: 'test1', destination: 'test1')
      word2 = NormalizeWord.create!(entered_source: 'test2', entered_destination: '', source: 'test2', destination: 'test2')

      get admin_food_dish_word_normalize_words_path

      expect(response.body).to include('test1')
      expect(response.body).to include('test2')
    end
  end

  describe 'GET /admin/food/dish/word/normalize_words/new' do
    it 'returns http success' do
      get new_admin_food_dish_word_normalize_word_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/food/dish/word/normalize_words' do
    context '正常系' do
      it 'creates a new NormalizeWord and redirects to index' do
        expect do
          post admin_food_dish_word_normalize_words_path, params: { normalize_word: { source: 'test_source', destination: 'test_dest' } }
        end.to change(NormalizeWord, :count).by(1)

        expect(response).to redirect_to(admin_food_dish_word_normalize_words_path)
        follow_redirect!
        expect(response.body).to include('正規化ワードを作成しました')
      end
    end

    context '異常系' do
      it 'renders new template on validation error' do
        # sourceが空でバリデーションエラー
        post admin_food_dish_word_normalize_words_path, params: { normalize_word: { source: '', destination: '' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('新規作成')
      end
    end
  end

  describe 'GET /admin/food/dish/word/normalize_words/:id/edit' do
    it 'returns http success' do
      word = NormalizeWord.create!(entered_source: 'test', entered_destination: '', source: 'test', destination: 'test')
      get edit_admin_food_dish_word_normalize_word_path(word)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /admin/food/dish/word/normalize_words/:id' do
    let(:word) { NormalizeWord.create!(entered_source: 'test', entered_destination: '', source: 'test', destination: 'test') }

    context '正常系' do
      it 'updates the NormalizeWord and redirects to index' do
        patch admin_food_dish_word_normalize_word_path(word), params: { normalize_word: { source: 'updated_source', destination: 'updated_dest' } }

        expect(response).to redirect_to(admin_food_dish_word_normalize_words_path)
        follow_redirect!
        expect(response.body).to include('正規化ワードを更新しました')
      end
    end

    context '異常系' do
      it 'renders edit template on validation error' do
        patch admin_food_dish_word_normalize_word_path(word), params: { normalize_word: { source: '', destination: '' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('編集')
      end
    end
  end

  describe 'DELETE /admin/food/dish/word/normalize_words/:id' do
    it 'deletes the NormalizeWord and redirects to index' do
      word = NormalizeWord.create!(entered_source: 'test', entered_destination: '', source: 'test', destination: 'test')

      expect do
        delete admin_food_dish_word_normalize_word_path(word)
      end.to change(NormalizeWord, :count).by(-1)

      expect(response).to redirect_to(admin_food_dish_word_normalize_words_path)
      follow_redirect!
      expect(response.body).to include('正規化ワードを削除しました')
    end
  end
end
