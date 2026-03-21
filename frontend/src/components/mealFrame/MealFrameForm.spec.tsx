import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import { registerMutationHandler } from '../../lib/graphql/specHelper/mockServer';
import { AddMealFrameDocument } from '../../lib/graphql/generated/graphql';
import renderWithApollo from '../specHelper/renderWithApollo';
import MealFrameForm from './MealFrameForm';
import { userClick, userType } from '../specHelper/userEvents';

describe('<MealFrameForm>', () => {
  describe('バリデーション表示', () => {
    beforeEach(() => {
      renderWithApollo(<MealFrameForm onSubmitSucceeded={() => {}} />);
    });

    it('枠名が空のまま送信するとバリデーションエラーが表示される', async () => {
      await userClick(screen, 'submitMealFrameButton');

      expect(screen.getByText('枠名を入力してください。')).toBeInTheDocument();
    });

    it('枠名を入力して送信するとバリデーションエラーが表示されない', async () => {
      registerMutationHandler(AddMealFrameDocument, {
        addMealFrame: {
          mealFrameId: 1,
        },
      });

      await userType(screen, 'mealFrameName', '週末枠');
      await userClick(screen, 'submitMealFrameButton');

      expect(screen.queryByText('枠名を入力してください。')).not.toBeInTheDocument();
    });
  });
});
