import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import renderWithApollo from '../../specHelper/renderWithApollo';
import {
  registerMutationHandler,
  registerQueryHandler,
} from '../../../lib/graphql/specHelper/mockServer';
import SourceIndex from './index';
import {
  DishesPerSourceDocument,
  RemoveDishSourceDocument,
} from '../../../lib/graphql/generated/graphql';
import { userClick } from '../../specHelper/userEvents';

describe('<SourceIndex>', () => {
  const dishSourceNotHavingDishes = {
    id: 1,
    name: '削除されるやつ',
    type: 2,
  };

  beforeEach(() => {
    registerQueryHandler(DishesPerSourceDocument, {
      dishesPerSource: [
        {
          __typename: 'DishesForDisplayWithSource',
          dishSource: {
            __typename: 'DishSource',
            ...dishSourceNotHavingDishes,
          },
          dishesPerMealPosition: [],
        },
      ],
    });

    renderWithApollo(<SourceIndex />);
  });

  describe('when remove dish source', () => {
    it('succeeds with expected graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        RemoveDishSourceDocument,
        {
          removeDishSource: {
            dishSourceId: 1,
          },
        },
      );

      await userClick(
        screen,
        `dishSourceRemove-${dishSourceNotHavingDishes.id}`,
      );

      expect(getLatestMutationVariables()).toEqual({
        dishSourceId: dishSourceNotHavingDishes.id,
      });
    });
  });
});
