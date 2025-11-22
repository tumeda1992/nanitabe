import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import renderWithApollo from '../../../../specHelper/renderWithApollo';
import {
  registerMutationHandler,
  registerQueryHandler,
} from '../../../../../lib/graphql/specHelper/mockServer';
import { userClick } from '../../../../specHelper/userEvents';
import WeekCalender from '../../../WeekCalender';
import {
  AddMealDocument,
  ExistingDishesForRegisteringWithMealDocument,
  MealsForCalenderDocument,
} from '../../../../../lib/graphql/generated/graphql';
import { MEAL_TYPE } from '../../../../../features/meal/const';

jest.mock('next/router', () => require('next-router-mock'));

const buildNewMealGraphQLParams = (newMeal) => {
  return {
    ...newMeal,
    date: newMeal.date.toISOString(),
  };
};

describe('assign dish on week calender', () => {
  const registeredDish = {
    id: 55,
    name: '生姜焼き',
    mealPosition: 2,
    comment: null,
    dishSourceName: null,
  };

  const newMealWithRequiredParams = {
    date: new Date(2023, 5, 26),
    mealType: MEAL_TYPE.DINNER,
  };

  beforeEach(() => {
    registerQueryHandler(ExistingDishesForRegisteringWithMealDocument, {
      existingDishesForRegisteringWithMeal: [
        {
          __typename: 'Dish',
          ...registeredDish,
        },
      ],
    });

    registerQueryHandler(MealsForCalenderDocument, {
      mealsForCalender: [],
    });

    renderWithApollo(<WeekCalender date={new Date(2023, 5, 26)} />);
  });

  describe('when assign dish', () => {
    it('succeeds with expected graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        AddMealDocument,
        {
          addMeal: {
            mealId: 1,
          },
        },
      );

      await userClick(screen, 'calenderMenu');
      await userClick(screen, 'calenderMenu-assignDish');
      await userClick(
        screen,
        `mealTypeOption-${newMealWithRequiredParams.mealType}`,
      );
      await userClick(screen, `existingDish-${registeredDish.id}`);
      await userClick(
        screen,
        `weekCalendarDateOf${newMealWithRequiredParams.date.toISOString()}`,
      );

      expect(getLatestMutationVariables()).toEqual({
        dishId: registeredDish.id,
        meal: buildNewMealGraphQLParams(newMealWithRequiredParams),
      });
    });
  });
});
