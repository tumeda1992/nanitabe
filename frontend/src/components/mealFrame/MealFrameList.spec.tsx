import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import { registerQueryHandler, registerMutationHandler } from '../../lib/graphql/specHelper/mockServer';
import { MealFramesDocument, DeleteMealFrameDocument } from '../../lib/graphql/generated/graphql';
import renderWithApollo from '../specHelper/renderWithApollo';
import MealFrameList from './MealFrameList';
import { userClick } from '../specHelper/userEvents';

describe('<MealFrameList>', () => {
  describe('一覧表示', () => {
    it('枠名の一覧が表示される', async () => {
      registerQueryHandler(MealFramesDocument, {
        mealFrames: [
          { __typename: 'MealFrameForList', id: 1, name: '週末枠' },
          { __typename: 'MealFrameForList', id: 2, name: '平日枠' },
        ],
      });

      renderWithApollo(<MealFrameList />);

      expect(await screen.findByText('週末枠')).toBeInTheDocument();
      expect(await screen.findByText('平日枠')).toBeInTheDocument();
    });

    it('枠ごとに編集リンクが表示される', async () => {
      registerQueryHandler(MealFramesDocument, {
        mealFrames: [
          { __typename: 'MealFrameForList', id: 1, name: '週末枠' },
          { __typename: 'MealFrameForList', id: 2, name: '平日枠' },
        ],
      });

      renderWithApollo(<MealFrameList />);

      expect(await screen.findByTestId('editMealFrame-1')).toBeInTheDocument();
      expect(await screen.findByTestId('editMealFrame-2')).toBeInTheDocument();
    });

    it('枠ごとに削除ボタンが表示される', async () => {
      registerQueryHandler(MealFramesDocument, {
        mealFrames: [
          { __typename: 'MealFrameForList', id: 1, name: '週末枠' },
        ],
      });

      renderWithApollo(<MealFrameList />);

      expect(await screen.findByTestId('deleteMealFrame-1')).toBeInTheDocument();
    });

    it('枠がない場合は空メッセージが表示される', async () => {
      registerQueryHandler(MealFramesDocument, {
        mealFrames: [],
      });

      renderWithApollo(<MealFrameList />);

      expect(await screen.findByText('枠がありません。')).toBeInTheDocument();
    });
  });

  describe('削除', () => {
    it('削除ボタンをクリックするとdeleteMealFrameが呼ばれる', async () => {
      registerQueryHandler(MealFramesDocument, {
        mealFrames: [
          { __typename: 'MealFrameForList', id: 1, name: '週末枠' },
        ],
      });

      const { mutationInterceptor } = registerMutationHandler(DeleteMealFrameDocument, {
        deleteMealFrame: {
          mealFrameId: 1,
        },
      });

      renderWithApollo(<MealFrameList />);

      await userClick(screen, 'deleteMealFrame-1');

      expect(mutationInterceptor).toHaveBeenCalled();
    });
  });
});
