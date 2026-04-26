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
import AddMealTabs from './AddMealTabs';
import { userClick } from '../../../specHelper/userEvents';

describe('<AddMealTabs>', () => {
  const defaultDate = '2026-03-21';
  const onAddSucceeded = jest.fn();

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

  it('初期表示: 「食事」タブが選択された状態で AddMeal が表示される', async () => {
    renderWithApollo(
      <AddMealTabs defaultDate={defaultDate} onAddSucceeded={onAddSucceeded} />,
    );

    expect(screen.getByTestId('addTypeMeal')).toBeInTheDocument();
    // AddMeal フォームのコンテンツが表示されていること（食事登録フォームの存在確認）
    expect(screen.getByTestId('mealDate')).toBeInTheDocument();
  });

  it('「枠」タブクリックで AddMealFrame が表示される', async () => {
    renderWithApollo(
      <AddMealTabs defaultDate={defaultDate} onAddSucceeded={onAddSucceeded} />,
    );

    await userClick(screen, 'addTypeFrame');

    expect(await screen.findByTestId('mealFrameSelect')).toBeInTheDocument();
  });

  it('「枠パターン適用」タブクリックで AddMealPattern が表示される', async () => {
    renderWithApollo(
      <AddMealTabs defaultDate={defaultDate} onAddSucceeded={onAddSucceeded} />,
    );

    await userClick(screen, 'addTypePattern');

    expect(await screen.findByTestId('patternSelect')).toBeInTheDocument();
  });
});
