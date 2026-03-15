import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import {
  registerQueryHandler,
} from '../../../lib/graphql/specHelper/mockServer';
import { ExistingDishesForRegisteringWithMealDocument } from '../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../specHelper/renderWithApollo';
import DishSearchPanel from './index';

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
});
