module Admin
  module Food
    module Dish
      module Word
        class NormalizeWordsController < ApplicationController
          def index
            @normalize_words = NormalizeWord.all
          end

          def new
            @normalize_word = NormalizeWord.new
          end

          def create
            @normalize_word = Business::Food::Dish::Word::Usecase::AddCommand.call(
              source: normalize_word_params[:source],
              destination: normalize_word_params[:destination],
            )
            redirect_to admin_food_dish_word_normalize_words_path, notice: "正規化ワードを作成しました"
          rescue Business::Base::Values::InvalidAttributeError => e
            @normalize_word = NormalizeWord.new(normalize_word_params)
            flash.now[:alert] = e.message
            render :new, status: :unprocessable_entity
          rescue Business::Food::Dish::Word::Errors::ReflectLatestNormalizeWordError => e
            @normalize_word = NormalizeWord.new(normalize_word_params)
            flash.now[:alert] = e.message
            render :new, status: :internal_server_error
          end

          def edit
            @normalize_word = NormalizeWord.find(params[:id])
          end

          def update
            Business::Food::Dish::Word::Usecase::UpdateCommand.call(
              normalize_word_id: params[:id].to_i,
              source: normalize_word_params[:source],
              destination: normalize_word_params[:destination],
            )
            redirect_to admin_food_dish_word_normalize_words_path, notice: "正規化ワードを更新しました"
          rescue Business::Base::Values::InvalidAttributeError => e
            @normalize_word = NormalizeWord.find(params[:id])
            @normalize_word.assign_attributes(normalize_word_params)
            flash.now[:alert] = e.message
            render :edit, status: :unprocessable_entity
          rescue Business::Food::Dish::Word::Errors::ReflectLatestNormalizeWordError => e
            @normalize_word = NormalizeWord.find(params[:id])
            @normalize_word.assign_attributes(normalize_word_params)
            flash.now[:alert] = e.message
            render :edit, status: :internal_server_error
          end

          def destroy
            Business::Food::Dish::Word::Usecase::RemoveCommand.call(
              normalize_word_id: params[:id].to_i,
            )
            redirect_to admin_food_dish_word_normalize_words_path, notice: "正規化ワードを削除しました"
          rescue Business::Food::Dish::Word::Errors::ReflectLatestNormalizeWordError => e
            @normalize_word = NormalizeWord.find(params[:id])
            @normalize_word.assign_attributes(normalize_word_params)
            flash.now[:alert] = e.message
            render :edit, status: :internal_server_error
          end

          private

          def normalize_word_params
            params.require(:normalize_word).permit(:source, :destination)
          end
        end
      end
    end
  end
end
