import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import { registerMutationHandler, registerQueryHandler } from '../../lib/graphql/specHelper/mockServer';
import { AddMealFramePatternDocument, MealFramesDocument } from '../../lib/graphql/generated/graphql';
import renderWithApollo from '../specHelper/renderWithApollo';
import MealFramePatternForm from './MealFramePatternForm';
import { userClick, userType } from '../specHelper/userEvents';

const mockMealFrames = [
  { __typename: 'MealFrameForList' as const, id: 1, name: '朝枠' },
  { __typename: 'MealFrameForList' as const, id: 2, name: '夜枠' },
];

describe('<MealFramePatternForm>', () => {
  beforeEach(() => {
    registerQueryHandler(MealFramesDocument, {
      mealFrames: mockMealFrames,
    });
  });

  describe('バリデーション表示', () => {
    beforeEach(() => {
      renderWithApollo(<MealFramePatternForm onSubmitSucceeded={() => {}} />);
    });

    it('パターン名が空のまま送信するとバリデーションエラーが表示される', async () => {
      await userClick(screen, 'submitMealFramePatternButton');

      expect(screen.getByText('パターン名を入力してください。')).toBeInTheDocument();
    });

    it('パターン名を入力して送信するとバリデーションエラーが表示されない', async () => {
      registerMutationHandler(AddMealFramePatternDocument, {
        addMealFramePattern: {
          mealFramePatternId: 1,
        },
      });

      await userType(screen, 'mealFramePatternName', '糖質オフ週');
      await userClick(screen, 'submitMealFramePatternButton');

      expect(screen.queryByText('パターン名を入力してください。')).not.toBeInTheDocument();
    });
  });

  describe('日スロット操作', () => {
    beforeEach(() => {
      renderWithApollo(<MealFramePatternForm onSubmitSucceeded={() => {}} />);
    });

    it('「日を追加」ボタンを押すと日スロットが追加される', async () => {
      expect(screen.queryByTestId('daySlot-0')).not.toBeInTheDocument();

      await userClick(screen, 'addDaySlotButton');

      expect(screen.getByTestId('daySlot-0')).toBeInTheDocument();
    });

    it('日スロットの削除ボタンを押すとそのスロットが削除される', async () => {
      await userClick(screen, 'addDaySlotButton');
      await userClick(screen, 'addDaySlotButton');

      expect(screen.getByTestId('daySlot-0')).toBeInTheDocument();
      expect(screen.getByTestId('daySlot-1')).toBeInTheDocument();

      await userClick(screen, 'removeDaySlot-0');

      // 1つ削除後はスロットが1つになる（daySlot-1 が消え daySlot-0 のみになる）
      expect(screen.getByTestId('daySlot-0')).toBeInTheDocument();
      expect(screen.queryByTestId('daySlot-1')).not.toBeInTheDocument();
    });
  });
});
