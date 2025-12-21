import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import {
  registerMutationHandler,
  registerQueryHandler,
} from '../../../lib/graphql/specHelper/mockServer';
import {
  AddDishDocument,
  DishSourcesDocument,
  AddDishWithNewSourceDocument,
} from '../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../specHelper/renderWithApollo';
import AddDish from './AddDish';
import {
  userChooseSelectBox,
  userClick,
  userType,
  userTypeAfterClearTextBox,
} from '../../specHelper/userEvents';
import { DISH_SOURCE_TYPE } from '../../../features/dish/source/const';

describe('<AddDish>', () => {
  const newDishWithRequiredParams = {
    name: 'ハンバーグ',
    mealPosition: 2,
  };

  const selectedDishSource = {
    id: 1,
    type: DISH_SOURCE_TYPE.YOUTUBE,
  };

  const registeredDishSource = {
    ...selectedDishSource,
    name: 'りゅうじ',
  };

  const newDishSource = {
    name: '最強のレシピサイト',
    type: DISH_SOURCE_TYPE.WEBSITE,
  };

  const newDishTag = {
    content: '白ワインに合う',
  };

  const newDishSourceRelationDetailOfRecipeWebsite = {
    recipeWebsiteUrl: 'https://youtube/ryuji/gyoza',
  };

  beforeEach(() => {
    registerQueryHandler(DishSourcesDocument, {
      dishSources: [registeredDishSource].map((dishSource) => {
        return {
          __typename: 'DishRegisteredWithMeal',
          ...dishSource,
        };
      }),
    });

    renderWithApollo(
      <AddDish
        onSchemaError={(schemaErrors) => {
          // スキーマエラーがあったときテストで把握しやすいようにログに出す
          console.log(schemaErrors);
        }}
      />,
    );
  });

  describe('when add dish', () => {
    it('succeeds with expected graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        AddDishDocument,
        {
          addDish: {
            dishId: 1,
          },
        },
      );

      await userType(screen, 'dishname', newDishWithRequiredParams.name);
      await userClick(screen, 'submitDishButton');

      expect(getLatestMutationVariables()).toEqual({
        dish: newDishWithRequiredParams,
        dishSource: null,
        dishSourceRelationDetail: null,
        dishTags: [],
      });
    });
  });

  describe('when add dish with existing source relation', () => {
    it('succeeds with expected graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        AddDishDocument,
        {
          addDish: {
            dishId: 1,
          },
        },
      );

      await userType(screen, 'dishname', newDishWithRequiredParams.name);

      await userChooseSelectBox(screen, 'existingDishSources', [
        `existingDishSource-${selectedDishSource.id}`,
      ]);
      await userTypeAfterClearTextBox(
        screen,
        'dishSourceRelationDetailRecipeWebsiteUrl',
        newDishSourceRelationDetailOfRecipeWebsite.recipeWebsiteUrl,
      );

      await userClick(screen, 'submitDishButton');

      expect(getLatestMutationVariables()).toEqual({
        dish: {
          ...newDishWithRequiredParams,
        },
        dishSource: selectedDishSource,
        dishSourceRelationDetail: newDishSourceRelationDetailOfRecipeWebsite,
        dishTags: [],
      });
    });
  });

  describe('when add dish with new source relation', () => {
    it('succeeds with expected graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        AddDishWithNewSourceDocument,
        {
          addDishWithNewSource: {
            dishId: 1,
            dishSourceId: 1,
          },
        },
      );

      await userType(screen, 'dishname', newDishWithRequiredParams.name);

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
          ...newDishWithRequiredParams,
        },
        dishSource: newDishSource,
        dishSourceRelationDetail: newDishSourceRelationDetailOfRecipeWebsite,
        dishTags: [],
      });
    });
  });

  describe('when add dish with new tag', () => {
    it('succeeds with expected graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        AddDishDocument,
        {
          addDish: {
            dishId: 1,
          },
        },
      );

      await userType(screen, 'dishname', newDishWithRequiredParams.name);

      await userClick(screen, 'appendDishTag');
      await userType(screen, 'newDishTag-0', newDishTag.content);

      await userClick(screen, 'submitDishButton');

      expect(getLatestMutationVariables()).toEqual({
        dish: {
          ...newDishWithRequiredParams,
        },
        dishSource: null,
        dishSourceRelationDetail: null,
        dishTags: [
          { content: newDishTag.content }
        ],
      });
    });
  });

  describe('when add dish with new source relation and new tag', () => {
    it('succeeds with expected graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        AddDishWithNewSourceDocument,
        {
          addDishWithNewSource: {
            dishId: 1,
            dishSourceId: 1,
          },
        },
      );

      await userType(screen, 'dishname', newDishWithRequiredParams.name);

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

      await userClick(screen, 'appendDishTag');
      await userType(screen, 'newDishTag-0', newDishTag.content);

      await userClick(screen, 'submitDishButton');

      expect(getLatestMutationVariables()).toEqual({
        dish: {
          ...newDishWithRequiredParams,
        },
        dishSource: newDishSource,
        dishSourceRelationDetail: newDishSourceRelationDetailOfRecipeWebsite,
        dishTags: [
          { content: newDishTag.content }
        ],
      });
    });
  });
});
