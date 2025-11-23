import React from 'react';
import '@testing-library/jest-dom';
import { fireEvent, screen, waitFor } from '@testing-library/react';
import AddMeal from './AddMeal';
import {
  AddMealWithNewDishAndNewSourceDocument,
  AddMealDocument,
  ExistingDishesForRegisteringWithMealDocument,
  DishSourcesDocument,
  AddMealWithNewDishDocument,
} from '../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../specHelper/renderWithApollo';
import {
  enterTextBox,
  userChooseSelectBox,
  userClick,
  userType,
  userTypeAfterClearTextBox,
} from '../../specHelper/userEvents';
import {
  registerMutationHandler,
  registerQueryHandler,
} from '../../../lib/graphql/specHelper/mockServer';
import { DISH_SOURCE_TYPE } from '../../../features/dish/source/const';

const clickSubmitButton = async () => {
  await userClick(screen, 'submitMealButton');
};

const buildNewMealGraphQLParams = (newMeal) => {
  return {
    ...newMeal,
    date: newMeal.date.toISOString(),
  };
};

describe('<AddMeal>', () => {
  const newDishWithRequiredParams = {
    name: 'ハンバーグ',
    mealPosition: 2,
  };
  const newMealWithRequiredParams = {
    date: new Date(2022, 1, 1),
    mealType: 3,
  };
  const existingDishId = 55;

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
    registerQueryHandler(ExistingDishesForRegisteringWithMealDocument, {
      existingDishesForRegisteringWithMeal: [
        {
          __typename: 'Dish',
          id: existingDishId,
          name: '生姜焼き',
          mealPosition: 2,
          comment: null,
          dishSourceName: null,
        },
      ],
    });

    registerQueryHandler(DishSourcesDocument, {
      dishSources: [registeredDishSource].map((dishSource) => {
        return {
          __typename: 'DishRegisteredWithMeal',
          ...dishSource,
        };
      }),
    });

    renderWithApollo(
      <AddMeal
        defaultDate={newMealWithRequiredParams.date}
        onSchemaError={(schemaErrors) => {
          // スキーマエラーがあったときテストで把握しやすいようにログに出す
          console.log(schemaErrors);
        }}
      />,
    );
  });

  describe('when add meal with new dish', () => {
    it('succeeds with expected required graphql params', async () => {
      const { getLatestMutationVariables, mutationInterceptor } =
        registerMutationHandler(AddMealWithNewDishDocument, {
          addMealWithNewDish: {
            mealId: 1,
            dishId: 1,
          },
        });

      await userClick(screen, 'optionOfRegisteringNewDish');
      enterTextBox(screen, 'dishname', newDishWithRequiredParams.name);
      fireEvent.click(screen.getByTestId('submitMealButton'));

      // fireEvent.clickなどで非同期イベントが起きたときに、非同期イベント終了を待つのに、クリックなどをactでくくるか結果をwaitForで待つ必要がある
      await waitFor(() => expect(mutationInterceptor).toHaveBeenCalledTimes(1));
      expect(getLatestMutationVariables()).toEqual({
        dish: newDishWithRequiredParams,
        dishSource: null,
        dishSourceRelationDetail: null,
        dishTags: [],
        meal: buildNewMealGraphQLParams(newMealWithRequiredParams),
      });
    });
  });

  describe('when add meal with existing dish', () => {
    it('succeeds with expected required graphql params', async () => {
      const { getLatestMutationVariables, mutationInterceptor } =
        registerMutationHandler(AddMealDocument, {
          addMeal: {
            mealId: 1,
          },
        });

      await userClick(screen, `existingDish-${existingDishId}`);

      await userClick(screen, 'submitMealButton');

      expect(mutationInterceptor).toHaveBeenCalledTimes(1);
      expect(getLatestMutationVariables()).toEqual({
        dishId: existingDishId,
        meal: buildNewMealGraphQLParams(newMealWithRequiredParams),
      });
    });
  });

  describe('when add meal with new dish with existing source', () => {
    it('succeeds with expected required graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        AddMealWithNewDishDocument,
        {
          addMealWithNewDish: {
            mealId: 1,
            dishId: 1,
          },
        },
      );

      await userClick(screen, 'optionOfRegisteringNewDish');
      await userType(screen, 'dishname', newDishWithRequiredParams.name);
      await userClick(
        screen,
        `mealPositionOption-${newDishWithRequiredParams.mealPosition}`,
      );

      await userChooseSelectBox(screen, 'existingDishSources', [
        `existingDishSource-${selectedDishSource.id}`,
      ]);

      await userTypeAfterClearTextBox(
        screen,
        'dishSourceRelationDetailRecipeWebsiteUrl',
        newDishSourceRelationDetailOfRecipeWebsite.recipeWebsiteUrl,
      );

      await clickSubmitButton();

      expect(getLatestMutationVariables()).toEqual({
        dish: newDishWithRequiredParams,
        dishSource: selectedDishSource,
        dishSourceRelationDetail: newDishSourceRelationDetailOfRecipeWebsite,
        dishTags: [],
        meal: buildNewMealGraphQLParams(newMealWithRequiredParams),
      });
    });
  });

  describe('when add meal with new dish with no source', () => {
    it('succeeds with expected required graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        AddMealWithNewDishDocument,
        {
          addMealWithNewDish: {
            mealId: 1,
            dishId: 1,
          },
        },
      );

      await userClick(screen, 'optionOfRegisteringNewDish');
      await userType(screen, 'dishname', newDishWithRequiredParams.name);
      await userClick(
        screen,
        `mealPositionOption-${newDishWithRequiredParams.mealPosition}`,
      );

      await clickSubmitButton();

      expect(getLatestMutationVariables()).toEqual({
        dish: newDishWithRequiredParams,
        dishSource: null,
        dishSourceRelationDetail: null,
        dishTags: [],
        meal: buildNewMealGraphQLParams(newMealWithRequiredParams),
      });
    });
  });

  describe('when add meal with new dish and new dish source', () => {
    it('succeeds with expected required graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        AddMealWithNewDishAndNewSourceDocument,
        {
          addMealWithNewDishAndNewSource: {
            mealId: 1,
            dishId: 1,
            dishSourceId: 1,
          },
        },
      );

      await userClick(screen, 'optionOfRegisteringNewDish');
      await userType(screen, 'dishname', newDishWithRequiredParams.name);
      await userClick(
        screen,
        `mealPositionOption-${newDishWithRequiredParams.mealPosition}`,
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

      await clickSubmitButton();

      expect(getLatestMutationVariables()).toEqual({
        dish: newDishWithRequiredParams,
        dishSource: newDishSource,
        dishSourceRelationDetail: newDishSourceRelationDetailOfRecipeWebsite,
        dishTags: [],
        meal: buildNewMealGraphQLParams(newMealWithRequiredParams),
      });
    });
  });

  describe('when add meal with new dish with tag', () => {
    it('succeeds with expected required graphql params', async () => {
      const { getLatestMutationVariables, mutationInterceptor } =
        registerMutationHandler(AddMealWithNewDishDocument, {
          addMealWithNewDish: {
            mealId: 1,
            dishId: 1,
          },
        });

      await userClick(screen, 'optionOfRegisteringNewDish');
      enterTextBox(screen, 'dishname', newDishWithRequiredParams.name);

      await userClick(screen, 'appendDishTag');
      await userType(screen, 'newDishTag-0', newDishTag.content);

      fireEvent.click(screen.getByTestId('submitMealButton'));

      // fireEvent.clickなどで非同期イベントが起きたときに、非同期イベント終了を待つのに、クリックなどをactでくくるか結果をwaitForで待つ必要がある
      await waitFor(() => expect(mutationInterceptor).toHaveBeenCalledTimes(1));
      expect(getLatestMutationVariables()).toEqual({
        dish: newDishWithRequiredParams,
        dishSource: null,
        dishSourceRelationDetail: null,
        dishTags: [
          { content: newDishTag.content }
        ],
        meal: buildNewMealGraphQLParams(newMealWithRequiredParams),
      });
    });
  });

  describe('when add meal with new dish, new tag and new dish source', () => {
    it('succeeds with expected required graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        AddMealWithNewDishAndNewSourceDocument,
        {
          addMealWithNewDishAndNewSource: {
            mealId: 1,
            dishId: 1,
            dishSourceId: 1,
          },
        },
      );

      await userClick(screen, 'optionOfRegisteringNewDish');
      await userType(screen, 'dishname', newDishWithRequiredParams.name);
      await userClick(
        screen,
        `mealPositionOption-${newDishWithRequiredParams.mealPosition}`,
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

      await userClick(screen, 'appendDishTag');
      await userType(screen, 'newDishTag-0', newDishTag.content);


      await clickSubmitButton();

      expect(getLatestMutationVariables()).toEqual({
        dish: newDishWithRequiredParams,
        dishSource: newDishSource,
        dishSourceRelationDetail: newDishSourceRelationDetailOfRecipeWebsite,
        dishTags: [
          { content: newDishTag.content }
        ],
        meal: buildNewMealGraphQLParams(newMealWithRequiredParams),
      });
    });
  });
});
