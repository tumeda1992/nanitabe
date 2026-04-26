import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import { registerQueryHandler } from '../../../../lib/graphql/specHelper/mockServer';
import {
  MealFramesDocument,
  DishEffortLevelsDocument,
  DishSourcesDocument,
  MealFramePatternsDocument,
} from '../../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../../specHelper/renderWithApollo';
import AddMealIcon from './AddMealIcon';
import { userClick } from '../../../specHelper/userEvents';

describe('<AddMealIcon>', () => {
  const dateForAdd = new Date('2026-03-21T09:00:00');

  beforeEach(() => {
    registerQueryHandler(DishEffortLevelsDocument, {
      dishEffortLevels: [],
    });
    registerQueryHandler(DishSourcesDocument, {
      dishSources: [],
    });
    registerQueryHandler(MealFramesDocument, {
      mealFrames: [
        { __typename: 'MealFrameForList', id: 1, name: '週末枠' },
      ],
    });
    registerQueryHandler(MealFramePatternsDocument, {
      mealFramePatterns: [],
    });
  });

  describe('タイプセレクタ', () => {
    it('「+」ボタンをクリックするとモーダルが開き、食事登録がデフォルトで表示される', async () => {
      renderWithApollo(
        <AddMealIcon dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      await userClick(screen, 'addMealIconOpener');

      expect(screen.getByTestId('addTypeSelector')).toBeInTheDocument();
      expect(screen.getByTestId('addTypeMeal')).toBeInTheDocument();
      expect(screen.getByTestId('addTypeFrame')).toBeInTheDocument();
      expect(screen.getByTestId('addTypePattern')).toBeInTheDocument();
    });

    it('「枠」タブをクリックすると枠登録フォームに切り替わる', async () => {
      renderWithApollo(
        <AddMealIcon dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      await userClick(screen, 'addMealIconOpener');
      await userClick(screen, 'addTypeFrame');

      expect(await screen.findByTestId('mealFrameSelect')).toBeInTheDocument();
    });

    it('「枠パターン適用」タブをクリックするとパターン適用フォームに切り替わる', async () => {
      renderWithApollo(
        <AddMealIcon dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      await userClick(screen, 'addMealIconOpener');
      await userClick(screen, 'addTypePattern');

      expect(await screen.findByTestId('patternSelect')).toBeInTheDocument();
    });
  });
});
