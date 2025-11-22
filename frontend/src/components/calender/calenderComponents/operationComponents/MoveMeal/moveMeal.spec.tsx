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
  ExistingDishesForRegisteringWithMealDocument,
  MealsForCalenderDocument,
  UpdateMealDocument,
} from '../../../../../lib/graphql/generated/graphql';

jest.mock('next/router', () => require('next-router-mock'));

const buildMealGraphQLParams = (meal) => {
  const { id, date, mealType, dish } = meal;
  return {
    id,
    mealType,
    date: date.toISOString(),
  };
};

describe('move dish on week calender', () => {
  const registeredDish = {
    id: 55,
    name: '生姜焼き',
    mealPosition: 2,
    comment: null,
    dishSourceRelation: null,
    evaluationScore: null,
  };
  const registeredMealWithoutDish = {
    id: 30,
    date: new Date(2023, 5, 26),
    mealType: 3,
    comment: null,
  };

  const moveTargetDate = new Date(2023, 5, 27);
  const movedMeal = {
    ...registeredMealWithoutDish,
    dish: registeredDish,
    date: moveTargetDate,
  };

  beforeEach(() => {
    registerQueryHandler(MealsForCalenderDocument, {
      mealsForCalender: [
        {
          __typename: 'MealsOfDate',
          date: '2023-06-26',
          meals: [
            {
              __typename: 'MealForCalender',
              ...registeredMealWithoutDish,
              dish: {
                ...registeredDish,
                dishSourceName: null,
              },
            },
          ],
        },
      ],
    });

    registerQueryHandler(ExistingDishesForRegisteringWithMealDocument, {
      existingDishesForRegisteringWithMeal: [
        {
          __typename: 'Dish',
          id: 55,
          name: '生姜焼き',
          mealPosition: 2,
          comment: null,
          dishSourceName: null,
        },
      ],
    });

    renderWithApollo(<WeekCalender date={registeredMealWithoutDish.date} />);
  });

  describe('when assign dish', () => {
    it('succeeds with expected graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        UpdateMealDocument,
        {
          updateMeal: {
            mealId: movedMeal.id,
          },
        },
      );

      await userClick(screen, `mealMenuOpener-${movedMeal.id}`);
      await userClick(screen, 'mealMoveButton');
      await userClick(
        screen,
        `weekCalendarDateOf${moveTargetDate.toISOString()}`,
      );

      expect(getLatestMutationVariables()).toEqual({
        dishId: registeredDish.id,
        meal: buildMealGraphQLParams(movedMeal),
      });
    });
  });
});
