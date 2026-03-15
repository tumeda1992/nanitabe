import React from 'react';
import '@testing-library/jest-dom';
import { screen, waitFor } from '@testing-library/react';
import {
  registerMutationHandler,
} from '../../../lib/graphql/specHelper/mockServer';
import { BulkAddTagToDishesDocument } from '../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../specHelper/renderWithApollo';
import BulkTagDrawer from './index';
import { userType, userClick } from '../../specHelper/userEvents';

describe('<BulkTagDrawer>', () => {
  const dishIds = new Set([1, 2, 3]);
  const onOpenChange = jest.fn();

  beforeEach(() => {
    onOpenChange.mockClear();
  });

  describe('when tag name is empty', () => {
    it('disables the add button', () => {
      renderWithApollo(
        <BulkTagDrawer
          open={true}
          onOpenChange={onOpenChange}
          dishIds={dishIds}
        />,
      );

      const addButton = screen.getByTestId('bulkTagAddButton');
      expect(addButton).toBeDisabled();
    });
  });

  describe('when tag name is entered and add button is pressed', () => {
    it('calls bulkAddTagToDishes mutation with correct variables', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        BulkAddTagToDishesDocument,
        {
          bulkAddTagToDishes: {
            __typename: 'BulkAddTagToDishesPayload',
            dishIds: [1, 2, 3],
          },
        },
      );

      renderWithApollo(
        <BulkTagDrawer
          open={true}
          onOpenChange={onOpenChange}
          dishIds={dishIds}
        />,
      );

      await userType(screen, 'bulkTagNameInput', '和食');
      await userClick(screen, 'bulkTagAddButton');

      await waitFor(() => {
        expect(getLatestMutationVariables()).toEqual({
          dishIds: [1, 2, 3],
          tag: '和食',
        });
      });
    });

    it('calls onOpenChange(false) on mutation success', async () => {
      registerMutationHandler(BulkAddTagToDishesDocument, {
        bulkAddTagToDishes: {
          __typename: 'BulkAddTagToDishesPayload',
          dishIds: [1, 2, 3],
        },
      });

      renderWithApollo(
        <BulkTagDrawer
          open={true}
          onOpenChange={onOpenChange}
          dishIds={dishIds}
        />,
      );

      await userType(screen, 'bulkTagNameInput', '和食');
      await userClick(screen, 'bulkTagAddButton');

      await waitFor(() => {
        expect(onOpenChange).toHaveBeenCalledWith(false);
      });
    });
  });
});
