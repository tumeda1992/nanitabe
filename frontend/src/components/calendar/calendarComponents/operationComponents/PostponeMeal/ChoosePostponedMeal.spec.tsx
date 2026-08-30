import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ChoosePostponedMeal from './ChoosePostponedMeal';
import renderWithApollo from '../../../../specHelper/renderWithApollo';
import { MEAL_TYPE } from '../../../../../features/meal/const';

const buildUsePostponedMealModeResult = (overrides = {}) => ({
  changeCalendarModeToDisplayCalendarMode: jest.fn(),
  postponedMeals: [],
  ...overrides,
});

describe('<ChoosePostponedMeal>', () => {
  it('タイトル「延期した食事」が表示されること', () => {
    renderWithApollo(
      <ChoosePostponedMeal
        usePostponedMealModeResult={buildUsePostponedMealModeResult()}
      />,
    );
    expect(screen.getByText('延期した食事')).toBeInTheDocument();
  });

  it('延期した食事が0件のとき空状態が表示されること', () => {
    renderWithApollo(
      <ChoosePostponedMeal
        usePostponedMealModeResult={buildUsePostponedMealModeResult({
          postponedMeals: [],
        })}
      />,
    );
    expect(screen.getByTestId('choosePostponedMeal-empty')).toBeInTheDocument();
    expect(screen.getByText('延期した食事はありません')).toBeInTheDocument();
  });

  it('createdAt降順で渡された順のまま、料理名と時間帯が並んで表示されること', () => {
    const postponedMeals = [
      { id: 3, dishId: 42, dishName: '豚の角煮', mealType: MEAL_TYPE.DINNER, createdAt: '2026-08-30T20:05:00Z' },
      { id: 2, dishId: 17, dishName: 'カオマンガイ', mealType: MEAL_TYPE.LUNCH, createdAt: '2026-08-30T12:00:00Z' },
      { id: 1, dishId: 42, dishName: '豚の角煮', mealType: MEAL_TYPE.DINNER, createdAt: '2026-08-29T20:10:00Z' },
    ];
    renderWithApollo(
      <ChoosePostponedMeal
        usePostponedMealModeResult={buildUsePostponedMealModeResult({
          postponedMeals,
        })}
      />,
    );

    const rows = screen.getAllByText(/豚の角煮|カオマンガイ/);
    expect(rows.map((row) => row.textContent)).toEqual([
      '豚の角煮',
      'カオマンガイ',
      '豚の角煮',
    ]);

    // 同名の行が2件、それぞれ別行として表示される（重複を許容）
    expect(screen.getByTestId('choosePostponedMeal-row-1')).toBeInTheDocument();
    expect(screen.getByTestId('choosePostponedMeal-row-3')).toBeInTheDocument();

    expect(screen.getByTestId('choosePostponedMeal-row-3')).toHaveTextContent('夜');
    expect(screen.getByTestId('choosePostponedMeal-row-2')).toHaveTextContent('昼');
  });

  it('コメントがある行には2行目としてコメントが表示されること', () => {
    const postponedMeals = [
      {
        id: 1,
        dishId: 42,
        dishName: '豚の角煮',
        mealType: MEAL_TYPE.DINNER,
        comment: '急遽外食になったため延期',
        createdAt: '2026-08-30T20:05:00Z',
      },
    ];
    renderWithApollo(
      <ChoosePostponedMeal
        usePostponedMealModeResult={buildUsePostponedMealModeResult({
          postponedMeals,
        })}
      />,
    );

    expect(
      screen.getByTestId('choosePostponedMeal-comment-1'),
    ).toHaveTextContent('急遽外食になったため延期');
  });

  it('コメントがない行では2行目（コメント表示）が出ないこと', () => {
    const postponedMeals = [
      {
        id: 1,
        dishId: 42,
        dishName: '豚の角煮',
        mealType: MEAL_TYPE.DINNER,
        comment: null,
        createdAt: '2026-08-30T20:05:00Z',
      },
    ];
    renderWithApollo(
      <ChoosePostponedMeal
        usePostponedMealModeResult={buildUsePostponedMealModeResult({
          postponedMeals,
        })}
      />,
    );

    expect(
      screen.queryByTestId('choosePostponedMeal-comment-1'),
    ).not.toBeInTheDocument();
  });

  it('行タップで selectPostponedMeal が呼ばれること', async () => {
    const selectPostponedMeal = jest.fn();
    const postponedMeal = {
      id: 1,
      dishId: 42,
      dishName: '豚の角煮',
      mealType: MEAL_TYPE.DINNER,
      comment: null,
      createdAt: '2026-08-30T20:05:00Z',
    };
    renderWithApollo(
      <ChoosePostponedMeal
        usePostponedMealModeResult={buildUsePostponedMealModeResult({
          postponedMeals: [postponedMeal],
          selectPostponedMeal,
        })}
      />,
    );

    await userEvent.click(screen.getByTestId('choosePostponedMeal-row-1'));
    expect(selectPostponedMeal).toHaveBeenCalledWith(postponedMeal);
  });

  it('×タップで changeCalendarModeToDisplayCalendarMode が呼ばれること', async () => {
    const changeCalendarModeToDisplayCalendarMode = jest.fn();
    renderWithApollo(
      <ChoosePostponedMeal
        usePostponedMealModeResult={buildUsePostponedMealModeResult({
          changeCalendarModeToDisplayCalendarMode,
        })}
      />,
    );

    await userEvent.click(screen.getByTestId('choosePostponedMeal-closeBtn'));
    expect(changeCalendarModeToDisplayCalendarMode).toHaveBeenCalled();
  });
});
