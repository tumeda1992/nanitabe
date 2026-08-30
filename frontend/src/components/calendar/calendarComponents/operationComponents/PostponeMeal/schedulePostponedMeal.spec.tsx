import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import { format } from 'date-fns';
import renderWithApollo from '../../../../specHelper/renderWithApollo';
import {
  registerMutationHandler,
  registerQueryHandler,
} from '../../../../../lib/graphql/specHelper/mockServer';
import { userClick } from '../../../../specHelper/userEvents';
import WeekCalendar from '../../../WeekCalendar';
import {
  SchedulePostponedMealDocument,
  PostponedMealsDocument,
  MealsForCalenderDocument,
} from '../../../../../lib/graphql/generated/graphql';
import { MEAL_TYPE } from '../../../../../features/meal/const';

describe('schedule postponed meal on week calendar', () => {
  const postponedMeal = {
    id: 3,
    dishId: 42,
    dishName: '豚の角煮',
    mealType: MEAL_TYPE.DINNER,
    comment: null,
    createdAt: '2026-08-29T20:10:00Z',
  };

  // 同じ料理の別の意思。確定しても残ることを確かめるために置く
  const anotherPostponedMealOfSameDish = {
    id: 4,
    dishId: 42,
    dishName: '豚の角煮',
    mealType: MEAL_TYPE.DINNER,
    comment: null,
    createdAt: '2026-08-30T20:05:00Z',
  };

  const targetDate = new Date(2023, 5, 26);

  beforeEach(() => {
    registerQueryHandler(PostponedMealsDocument, {
      postponedMeals: [
        { __typename: 'PostponedMealForList', ...postponedMeal },
        {
          __typename: 'PostponedMealForList',
          ...anotherPostponedMealOfSameDish,
        },
      ],
    });

    registerQueryHandler(MealsForCalenderDocument, {
      mealsForCalender: [],
    });

    renderWithApollo(<WeekCalendar date={targetDate} />);
  });

  const openScheduleChosenPostponedMealPanel = async () => {
    await userClick(screen, 'calendarMenu');
    await userClick(screen, 'calendarMenu-postponedMeal');
    await userClick(screen, `choosePostponedMeal-row-${postponedMeal.id}`);
  };

  it('確定パネルに時間帯選択UI（ラジオ）が無いこと', async () => {
    await openScheduleChosenPostponedMealPanel();

    expect(
      screen.getByTestId('scheduleChosenPostponedMeal-dishName'),
    ).toHaveTextContent(postponedMeal.dishName);
    expect(screen.queryAllByRole('radio')).toHaveLength(0);
  });

  it('日付タップで schedulePostponedMeal mutation が呼ばれること', async () => {
    await openScheduleChosenPostponedMealPanel();

    const { getLatestMutationVariables } = registerMutationHandler(
      SchedulePostponedMealDocument,
      {
        schedulePostponedMeal: {
          mealId: 100,
        },
      },
    );

    await userClick(
      screen,
      `weekCalendarDateOf${format(targetDate, 'yyyy-MM-dd')}`,
    );

    expect(getLatestMutationVariables()).toEqual({
      postponedMealId: postponedMeal.id,
      date: targetDate.toISOString(),
    });
  });

  it('確定した行が一覧から消え、同じ料理の他の行は残ること', async () => {
    await openScheduleChosenPostponedMealPanel();

    registerMutationHandler(SchedulePostponedMealDocument, {
      schedulePostponedMeal: { mealId: 100 },
    });
    // 確定後のserver状態。確定した行だけが消える
    registerQueryHandler(PostponedMealsDocument, {
      postponedMeals: [
        {
          __typename: 'PostponedMealForList',
          ...anotherPostponedMealOfSameDish,
        },
      ],
    });

    await userClick(
      screen,
      `weekCalendarDateOf${format(targetDate, 'yyyy-MM-dd')}`,
    );

    // 一覧を開き直す
    await userClick(screen, 'calendarMenu');
    await userClick(screen, 'calendarMenu-postponedMeal');

    expect(
      screen.queryByTestId(`choosePostponedMeal-row-${postponedMeal.id}`),
    ).not.toBeInTheDocument();
    expect(
      screen.getByTestId(
        `choosePostponedMeal-row-${anotherPostponedMealOfSameDish.id}`,
      ),
    ).toBeInTheDocument();
  });
});
