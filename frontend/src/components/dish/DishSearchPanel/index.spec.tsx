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
  describe('when mode=page', () => {
    beforeEach(() => {
      registerQueryHandler(ExistingDishesForRegisteringWithMealDocument, {
        existingDishesForRegisteringWithMeal: [registeredDish1, registeredDish2],
      });

      renderWithApollo(
        <DishSearchPanel
          mode="page"
          onEdit={() => {}}
          onDelete={() => {}}
        />,
      );
    });

    it('shows dish list on initial render', async () => {
      expect(await screen.findByText('ハンバーグ')).toBeInTheDocument();
      expect(screen.getByText('味噌汁')).toBeInTheDocument();
    });

    it('shows Library card (... menu) for each dish', async () => {
      await screen.findByText('ハンバーグ');
      const menuButtons = screen.getAllByLabelText('操作メニュー');
      expect(menuButtons.length).toBeGreaterThan(0);
    });
  });

  describe('when mode=picker', () => {
    beforeEach(() => {
      registerQueryHandler(ExistingDishesForRegisteringWithMealDocument, {
        existingDishesForRegisteringWithMeal: [registeredDish1],
      });

      renderWithApollo(
        <DishSearchPanel
          mode="picker"
          selectedDishId={null}
          onSelect={() => {}}
        />,
      );
    });

    it('shows Picker card for each dish', async () => {
      expect(await screen.findByText('ハンバーグ')).toBeInTheDocument();
    });
  });
});
