import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import { registerMutationHandler } from '../../../../lib/graphql/specHelper/mockServer';
import Icon from './index';
import renderWithApollo from '../../../specHelper/renderWithApollo';
import { RemoveDishDocument } from '../../../../lib/graphql/generated/graphql';
import { userClick } from '../../../specHelper/userEvents';

describe('<Icon>', () => {
  const dishWithoutNotDishField = {
    id: 55,
    name: '生姜焼き',
    mealPosition: 2,
  };
  const registeredDishNotHavingMeals = {
    ...dishWithoutNotDishField,
    meals: [],
  };

  const registeredMeal = {
    id: 30,
    date: new Date(2022, 1, 1),
    mealType: 3,
    dish: dishWithoutNotDishField,
  };

  const registeredDishHavingMeals = {
    ...dishWithoutNotDishField,
    meals: [registeredMeal],
  };

  describe('when remove dish', () => {
    beforeEach(() => {
      renderWithApollo(<Icon dish={registeredDishNotHavingMeals} />);
    });

    it('succeeds with expected required graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        RemoveDishDocument,
        {
          removeDish: {
            dishId: registeredDishNotHavingMeals.id,
          },
        },
      );

      await userClick(screen, 'dishDeleteButton');

      expect(getLatestMutationVariables()).toEqual({
        dishId: registeredDishNotHavingMeals.id,
      });
    });
  });

  describe('when remove dish having registered meal', () => {
    beforeEach(() => {
      renderWithApollo(<Icon dish={registeredDishHavingMeals} />);
    });

    it('does not send graphql request', async () => {
      const { mutationInterceptor } = registerMutationHandler(
        RemoveDishDocument,
        {
          removeDish: {
            dishId: registeredDishHavingMeals.id,
          },
        },
      );

      await userClick(screen, 'dishDeleteButton');

      expect(mutationInterceptor).toHaveBeenCalledTimes(0);
    });
  });
});
