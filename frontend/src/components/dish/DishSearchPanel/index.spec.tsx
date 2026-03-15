import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import {
  registerQueryHandler,
} from '../../../lib/graphql/specHelper/mockServer';
import { ExistingDishesForRegisteringWithMealDocument } from '../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../specHelper/renderWithApollo';
import DishSearchPanel from './index';
import { waitFor } from '@testing-library/react';

const registeredDish1 = {
  __typename: 'Dish' as const,
  id: 1,
  name: 'ハンバーグ',
  mealPosition: 2,
  comment: null,
  dishSourceName: 'りゅうじ',
  evaluationScore: 4,
};

const registeredDish2 = {
  __typename: 'Dish' as const,
  id: 2,
  name: '味噌汁',
  mealPosition: 4,
  comment: null,
  dishSourceName: null,
  evaluationScore: null,
};

describe('<DishSearchPanel>', () => {
  describe('when renderCard renders dish name', () => {
    beforeEach(() => {
      registerQueryHandler(ExistingDishesForRegisteringWithMealDocument, {
        existingDishesForRegisteringWithMeal: [registeredDish1, registeredDish2],
      });

      renderWithApollo(
        <DishSearchPanel
          renderCard={(dish) => (
            <div key={dish.id} data-testid={`card-${dish.id}`}>{dish.name}</div>
          )}
        />,
      );
    });

    it('shows dish list on initial render', async () => {
      expect(await screen.findByText('ハンバーグ')).toBeInTheDocument();
      expect(screen.getByText('味噌汁')).toBeInTheDocument();
    });

    it('renders each dish via renderCard', async () => {
      await screen.findByTestId('card-1');
      expect(screen.getByTestId('card-1')).toBeInTheDocument();
      expect(screen.getByTestId('card-2')).toBeInTheDocument();
    });
  });

  describe('when dishIdRegisteredWithMeal is passed', () => {
    it('includes dishIdRegisteredWithMeal in query variables', async () => {
      const { getLatestQueryVariables } = registerQueryHandler(
        ExistingDishesForRegisteringWithMealDocument,
        { existingDishesForRegisteringWithMeal: [registeredDish1] },
      );

      renderWithApollo(
        <DishSearchPanel
          dishIdRegisteredWithMeal={42}
          renderCard={(dish) => (
            <div key={dish.id} data-testid={`card-${dish.id}`}>{dish.name}</div>
          )}
        />,
      );

      await screen.findByTestId('card-1');

      await waitFor(() => {
        const variables = getLatestQueryVariables();
        expect(variables).not.toBeNull();
        expect(variables?.dishIdRegisteredWithMeal).toBe(42);
      });
    });

    it('does not include dishIdRegisteredWithMeal when not passed', async () => {
      const { getLatestQueryVariables } = registerQueryHandler(
        ExistingDishesForRegisteringWithMealDocument,
        { existingDishesForRegisteringWithMeal: [registeredDish1] },
      );

      renderWithApollo(
        <DishSearchPanel
          renderCard={(dish) => (
            <div key={dish.id} data-testid={`card-${dish.id}`}>{dish.name}</div>
          )}
        />,
      );

      await screen.findByTestId('card-1');

      await waitFor(() => {
        const variables = getLatestQueryVariables();
        expect(variables).not.toBeNull();
        // dishIdRegisteredWithMeal を渡さない場合、変数には null または未定義が入る（Apollo Client は null 変数をオミットすることがある）
        expect(variables?.dishIdRegisteredWithMeal ?? null).toBeNull();
      });
    });
  });
});
