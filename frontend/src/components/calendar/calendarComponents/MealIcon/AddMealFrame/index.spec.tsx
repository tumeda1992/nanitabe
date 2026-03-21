import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import {
  registerQueryHandler,
  registerMutationHandler,
} from '../../../../../lib/graphql/specHelper/mockServer';
import {
  MealFramesDocument,
  AddMealFrameEntryDocument,
} from '../../../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../../../specHelper/renderWithApollo';
import AddMealFrame from './index';
import { userChooseSelectBox, userClick } from '../../../../specHelper/userEvents';

describe('<AddMealFrame>', () => {
  const dateForAdd = new Date('2026-03-21T09:00:00');

  beforeEach(() => {
    registerQueryHandler(MealFramesDocument, {
      mealFrames: [
        { __typename: 'MealFrameForList', id: 1, name: '週末枠' },
        { __typename: 'MealFrameForList', id: 2, name: '平日枠' },
      ],
    });
  });

  describe('登録フォーム', () => {
    it('枠選択セレクトボックスが表示される', async () => {
      renderWithApollo(
        <AddMealFrame dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      expect(await screen.findByTestId('mealFrameSelect')).toBeInTheDocument();
      expect(await screen.findByTestId('mealFrameOption-1')).toBeInTheDocument();
      expect(await screen.findByTestId('mealFrameOption-2')).toBeInTheDocument();
    });

    it('食事タイプ選択セレクトボックスが表示される', async () => {
      renderWithApollo(
        <AddMealFrame dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      expect(await screen.findByTestId('mealTypeSelect')).toBeInTheDocument();
    });

    it('枠と食事タイプを選択して登録ボタンをクリックするとaddMealFrameEntryが呼ばれる', async () => {
      const { mutationInterceptor } = registerMutationHandler(
        AddMealFrameEntryDocument,
        {
          addMealFrameEntry: {
            mealFrameEntryId: 1,
          },
        },
      );

      renderWithApollo(
        <AddMealFrame dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      await userChooseSelectBox(screen, 'mealFrameSelect', ['mealFrameOption-1']);
      await userChooseSelectBox(screen, 'mealTypeSelect', ['mealTypeOption-1']);
      await userClick(screen, 'submitAddMealFrameButton');

      expect(mutationInterceptor).toHaveBeenCalled();
    });
  });
});
