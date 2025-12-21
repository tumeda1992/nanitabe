import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import {
  registerMutationHandler,
} from '../../../../lib/graphql/specHelper/mockServer';
import {
  UpdateDishDocument,
} from '../../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../../specHelper/renderWithApollo';
import EditDish from '../EditDish';
import {
  userChooseSelectBox,
  userClick,
  userTypeAfterClearTextBox,
} from '../../../specHelper/userEvents';
import { 
  registeredDish,
  registeredDishSource,
  updatedDishSourceRelation,
  registeredDishSource2,
  registerDishSourcesQuery,
} from './commonVariables';

beforeEach(() => {
  registerDishSourcesQuery();
});

describe('<EditDish>', () => {
  describe('edit existing dish having dish source relation, ', () => {
    const registeredDishWithDishSourceRelation = {
      ...registeredDish,
      dishSourceRelation: {
        dishSourceId: registeredDishSource2.id,
        recipeWebsiteUrl: 'https://youtube/ahoaho_channel',
        recipeBookPage: undefined,
        recipeSourceMemo: undefined,
      },
    };

    beforeEach(() => {
      renderWithApollo(
        <EditDish
          dish={registeredDishWithDishSourceRelation}
          onSchemaError={(schemaErrors) => {
            console.log('入力値バリデーションエラー');
            console.log(schemaErrors);
            // screen.debug();
          }}
        />,
      );
    });

    describe('when update update with different source relation', () => {
      it('succeeds with expected graphql params', async () => {
        const { getLatestMutationVariables } = registerMutationHandler(
          UpdateDishDocument,
          {
            updateDish: {
              dishId: 1,
            },
          },
        );

        await userChooseSelectBox(screen, 'existingDishSources', [
          `existingDishSource-${registeredDishSource.id}`,
        ]);

        await userTypeAfterClearTextBox(
          screen,
          'dishSourceRelationDetailRecipeWebsiteUrl',
          updatedDishSourceRelation.dishSourceRelationDetail.recipeWebsiteUrl,
        );

        await userClick(screen, 'submitDishButton');

        expect(getLatestMutationVariables()).toEqual({
          dish: {
            ...registeredDish,
          },
          dishSourceRelation: updatedDishSourceRelation,
          dishTags: [],
        });
      });
    });

    describe('when update update with no source relation', () => {
      it('succeeds with expected graphql params', async () => {
        const { getLatestMutationVariables } = registerMutationHandler(
          UpdateDishDocument,
          {
            updateDish: {
              dishId: 1,
            },
          },
        );

        await userChooseSelectBox(screen, 'existingDishSources', [
          'existingDishSource-novalue',
        ]);

        await userClick(screen, 'submitDishButton');

        expect(getLatestMutationVariables()).toEqual({
          dish: {
            ...registeredDish,
          },
          dishSourceRelation: null,
          dishTags: [],
        });
      });
    });
  });
});