import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import {
  registerQueryHandler,
  registerMutationHandler,
} from '../../../../lib/graphql/specHelper/mockServer';
import {
  DishSourcesDocument,
  UpdateDishDocument,
  UpdateDishWithNewSourceDocument,
} from '../../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../../specHelper/renderWithApollo';
import EditDish from '../EditDish';
import {
  userChooseSelectBox,
  userClick,
  userType,
  userTypeAfterClearTextBox,
} from '../../../specHelper/userEvents';
import { 
  registeredDish,
  registeredDishSource,
  registeredDishSource2,
  updatedDishSourceRelation,
  newDishSourceRelationDetailOfRecipeWebsite,
  newDishSource,
  updatedDish,
} from './commonVariables';
import { DISH_SOURCE_TYPE } from '../../../../features/dish/source/const';

export const registeredDishSourceOfRecipeBook = {
  id: 3,
  name: 'はじめての中華料理',
  type: DISH_SOURCE_TYPE.RECIPE_BOOK,
};

export const registeredDishSourceOfRestaurant = {
  id: 4,
  name: '蒲田',
  type: DISH_SOURCE_TYPE.RESTAURANT,
};

export const updatedDishSourceRelationOfRecipeBook = {
  dishId: updatedDish.id,
  dishSourceId: registeredDishSourceOfRecipeBook.id,
  dishSourceType: registeredDishSourceOfRecipeBook.type,
  dishSourceRelationDetail: {
    recipeBookPage: 50,
  },
};

export const updatedDishSourceRelationOfRestaurant = {
  dishId: updatedDish.id,
  dishSourceId: registeredDishSourceOfRestaurant.id,
  dishSourceType: registeredDishSourceOfRestaurant.type,
  dishSourceRelationDetail: {
    recipeSourceMemo: '改札出て10分',
  },
};

beforeEach(() => {
  registerQueryHandler(DishSourcesDocument, {
    dishSources: [
      registeredDishSource,
      registeredDishSource2,
      registeredDishSourceOfRecipeBook,
      registeredDishSourceOfRestaurant,
    ].map((dishSource) => {
      return {
        __typename: 'DishRegisteredWithMeal',
        ...dishSource,
      };
    }),
  });
});

describe('<EditDish>', () => {
  describe('edit existing dish having only dish fields, ', () => {
    beforeEach(() => {
      renderWithApollo(
        <EditDish
          dish={registeredDish}
          onSchemaError={(schemaErrors) => {
            console.log('入力値バリデーションエラー');
            // スキーマエラーがあったときテストで把握しやすいようにログに出す
            console.log(schemaErrors);
            // screen.debug();
          }}
        />,
      );
    });

    describe('about source relation', () => {
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

      describe('when update update with recipe book source relation', () => {
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
            `existingDishSource-${registeredDishSourceOfRecipeBook.id}`,
          ]);

          await userType(
            screen,
            'dishSourceRelationDetailRecipeBookPage',
            String(
              updatedDishSourceRelationOfRecipeBook.dishSourceRelationDetail
                .recipeBookPage,
            ),
          );

          await userClick(screen, 'submitDishButton');

          expect(getLatestMutationVariables()).toEqual({
            dish: {
              ...registeredDish,
            },
            dishSourceRelation: updatedDishSourceRelationOfRecipeBook,
            dishTags: [],
          });
        });
      });

      describe('when update update with source memo source relation', () => {
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
            `existingDishSource-${registeredDishSourceOfRestaurant.id}`,
          ]);

          await userTypeAfterClearTextBox(
            screen,
            'dishSourceRelationDetailRecipeSourceMemo',
            updatedDishSourceRelationOfRestaurant.dishSourceRelationDetail
              .recipeSourceMemo,
          );

          await userClick(screen, 'submitDishButton');

          expect(getLatestMutationVariables()).toEqual({
            dish: {
              ...registeredDish,
            },
            dishSourceRelation: updatedDishSourceRelationOfRestaurant,
            dishTags: [],
          });
        });
      });

      describe('when update dish with new source relation', () => {
        it('succeeds with expected graphql params', async () => {
          const { getLatestMutationVariables } = registerMutationHandler(
            UpdateDishWithNewSourceDocument,
            {
              updateDishWithNewSource: {
                dishId: 1,
              },
            },
          );

          await userClick(screen, 'optionOfRegisteringNewDishSource');

          await userType(screen, 'dishSourceName', newDishSource.name);
          await userChooseSelectBox(screen, 'dishSourceTypeOption', [
            `dishSourceTypeOption-${newDishSource.type}`,
          ]);
          await userTypeAfterClearTextBox(
            screen,
            'dishSourceRelationDetailRecipeWebsiteUrl',
            newDishSourceRelationDetailOfRecipeWebsite.recipeWebsiteUrl,
          );

          await userClick(screen, 'submitDishButton');

          expect(getLatestMutationVariables()).toEqual({
            dish: {
              ...registeredDish,
            },
            dishSource: newDishSource,
            dishSourceRelationDetail:
              newDishSourceRelationDetailOfRecipeWebsite,
            dishTags: [],
          });
        });
      });
    });
  });
});