import React from 'react';
import '@testing-library/jest-dom';
import { screen, waitFor } from '@testing-library/react';
import {
  registerQueryHandler,
  registerMutationHandler,
} from '../../../../../lib/graphql/specHelper/mockServer';
import {
  MealFramePatternsDocument,
  ApplyMealFramePatternDocument,
} from '../../../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../../../specHelper/renderWithApollo';
import AddMealPattern from './index';
import { userClick } from '../../../../specHelper/userEvents';
import userEvent from '@testing-library/user-event';

describe('<AddMealPattern>', () => {
  const dateForAdd = new Date('2026-04-28T09:00:00');

  const mockPatterns = [
    {
      __typename: 'MealFramePatternForList' as const,
      id: 1,
      name: '糖質オフ週',
      entries: [],
    },
    {
      __typename: 'MealFramePatternForList' as const,
      id: 2,
      name: '3日魚中心',
      entries: [],
    },
  ];

  beforeEach(() => {
    registerQueryHandler(MealFramePatternsDocument, {
      mealFramePatterns: mockPatterns,
    });
  });

  describe('パターン選択・開始日入力', () => {
    it('パターン一覧がセレクトボックスで表示される', async () => {
      renderWithApollo(
        <AddMealPattern dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      expect(await screen.findByTestId('patternSelect')).toBeInTheDocument();
      expect(await screen.findByTestId('patternOption-1')).toBeInTheDocument();
      expect(await screen.findByTestId('patternOption-2')).toBeInTheDocument();
    });

    it('開始日入力フィールドが表示され、デフォルトでクリックした日が入力されている', async () => {
      renderWithApollo(
        <AddMealPattern dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      const startDateInput = await screen.findByTestId('startDateInput') as HTMLInputElement;
      expect(startDateInput).toBeInTheDocument();
      expect(startDateInput.value).toBe('2026-04-28');
    });

    it('「適用する」ボタンが表示される', async () => {
      renderWithApollo(
        <AddMealPattern dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      expect(await screen.findByTestId('submitApplyPatternButton')).toBeInTheDocument();
    });
  });

  describe('パターン適用', () => {
    it('パターンと開始日を選択して適用するボタンをクリックするとapplyMealFramePatternが呼ばれる', async () => {
      const { mutationInterceptor } = registerMutationHandler(
        ApplyMealFramePatternDocument,
        {
          applyMealFramePattern: {
            appliedMealFramePatternId: 1,
          },
        },
      );

      renderWithApollo(
        <AddMealPattern dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      // パターンを選択
      const patternSelect = await screen.findByTestId('patternSelect');
      await userEvent.selectOptions(patternSelect, ['1']);

      // 適用ボタンをクリック
      await userClick(screen, 'submitApplyPatternButton');

      await waitFor(() => expect(mutationInterceptor).toHaveBeenCalledTimes(1));
    });

    it('パターン未選択の場合は適用するボタンがdisabledになる', async () => {
      renderWithApollo(
        <AddMealPattern dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      const submitButton = await screen.findByTestId('submitApplyPatternButton');
      expect(submitButton).toBeDisabled();
    });
  });
});
