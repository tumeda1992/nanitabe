import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import EditMeal from './EditMeal';
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
import {
  UpdateMealWithNewDishAndNewSourceDocument,
  UpdateMealDocument,
  ExistingDishesForRegisteringWithMealDocument,
  DishSourcesDocument,
  UpdateMealWithNewDishDocument,
} from '../../../lib/graphql/generated/graphql';
import { buildISODateString } from '../../../features/utils/dateUtils';
import { DISH_SOURCE_TYPE } from '../../../features/dish/source/const';

const clickSubmitButton = async () => {
  await userClick(screen, 'submitMealButton');
};

const buildGraphQLMeal = (meal) => {
  return {
    ...meal,
    date: meal.date.toISOString(),
  };
};

describe('<EditMeal>', () => {
  const registeredDish = {
    id: 55,
    name: '生姜焼き',
    mealPosition: 2,
    comment: null,
    dishSourceName: null,
  };
  const registeredMealWithoutDish = {
    id: 30,
    date: new Date(2022, 1, 1),
    mealType: 3,
  };
  const registeredMeal = {
    ...registeredMealWithoutDish,
    dish: registeredDish,
  };

  const updatedDish = {
    id: 57,
    name: '目玉焼き',
    mealPosition: 1,
    comment: null,
    dishSourceName: null,
  };
  const updatedMeal = {
    id: 30,
    date: new Date(2023, 2, 2),
    mealType: 2,
  };

  const newDishWithRequiredParams = {
    name: 'カレー',
    mealPosition: 3,
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
    registerQueryHandler(ExistingDishesForRegisteringWithMealDocument, {
      existingDishesForRegisteringWithMeal: [
        {
          __typename: 'Dish',
          ...registeredDish,
        },
        {
          __typename: 'Dish',
          ...updatedDish,
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
  });

  describe('edit existing meal having only meal and dish fields, ', () => {
    beforeEach(() => {
      renderWithApollo(
        <EditMeal
          meal={buildGraphQLMeal(registeredMeal)}
          onSchemaError={(schemaErrors) => {
            console.log('入力値バリデーションエラー');
            console.log(schemaErrors);
            // screen.debug();
          }}
        />,
      );
    });
    describe('when update meal with different one field', () => {
      it('succeeds with expected required graphql params', async () => {
        const { getLatestMutationVariables } = registerMutationHandler(
          UpdateMealDocument,
          {
            updateMeal: {
              mealId: registeredMeal.id,
            },
          },
        );

        await userClick(screen, `mealTypeOption-${updatedMeal.mealType}`);
        await clickSubmitButton();

        expect(getLatestMutationVariables()).toEqual({
          dishId: registeredDish.id,
          meal: buildGraphQLMeal({
            ...registeredMealWithoutDish,
            mealType: updatedMeal.mealType,
          }),
        });
      });
    });

    describe('when update meal with different existing dish', () => {
      it('succeeds with expected required graphql params', async () => {
        const { getLatestMutationVariables } = registerMutationHandler(
          UpdateMealDocument,
          {
            updateMeal: {
              mealId: registeredMeal.id,
            },
          },
        );
        await userClick(screen, `existingDish-${updatedDish.id}`);
        await clickSubmitButton();

        expect(getLatestMutationVariables()).toEqual({
          dishId: updatedDish.id,
          meal: buildGraphQLMeal(registeredMealWithoutDish),
        });
      });
    });

    describe('when update meal with different all meal fields', () => {
      it('succeeds with expected required graphql params', async () => {
        const { getLatestMutationVariables } = registerMutationHandler(
          UpdateMealDocument,
          {
            updateMeal: {
              mealId: registeredMeal.id,
            },
          },
        );

        enterTextBox(screen, 'mealDate', buildISODateString(updatedMeal.date));
        await userClick(screen, `mealTypeOption-${updatedMeal.mealType}`);
        await userClick(screen, `existingDish-${updatedDish.id}`);
        await clickSubmitButton();

        expect(getLatestMutationVariables()).toEqual({
          dishId: updatedDish.id,
          meal: buildGraphQLMeal(updatedMeal),
        });
      });
    });

    describe('when update meal with new dish with existing source', () => {
      it('succeeds with expected required graphql params', async () => {
        const { getLatestMutationVariables } = registerMutationHandler(
          UpdateMealWithNewDishDocument,
          {
            updateMealWithNewDish: {
              mealId: registeredMeal.id,
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
          meal: buildGraphQLMeal(registeredMealWithoutDish),
        });
      });
    });

    describe('when update meal with new dish and new dish source', () => {
      it('succeeds with expected required graphql params', async () => {
        const { getLatestMutationVariables } = registerMutationHandler(
          UpdateMealWithNewDishAndNewSourceDocument,
          {
            updateMealWithNewDishAndNewSource: {
              mealId: registeredMeal.id,
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
          meal: buildGraphQLMeal(registeredMealWithoutDish),
        });
      });
    });

    describe('when update meal with new dish having new tag with existing source', () => {
      it('succeeds with expected required graphql params', async () => {
        const { getLatestMutationVariables } = registerMutationHandler(
          UpdateMealWithNewDishDocument,
          {
            updateMealWithNewDish: {
              mealId: registeredMeal.id,
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

        await userClick(screen, 'appendDishTag');
        await userType(screen, 'newDishTag-0', newDishTag.content);

        await clickSubmitButton();

        expect(getLatestMutationVariables()).toEqual({
          dish: newDishWithRequiredParams,
          dishSource: selectedDishSource,
          dishSourceRelationDetail: newDishSourceRelationDetailOfRecipeWebsite,
          dishTags: [
            { content: newDishTag.content }
          ],
          meal: buildGraphQLMeal(registeredMealWithoutDish),
        });
      });
    });

    describe('when update meal with new dish having new tag and new dish source', () => {
      it('succeeds with expected required graphql params', async () => {
        const { getLatestMutationVariables } = registerMutationHandler(
          UpdateMealWithNewDishAndNewSourceDocument,
          {
            updateMealWithNewDishAndNewSource: {
              mealId: registeredMeal.id,
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
          meal: buildGraphQLMeal(registeredMealWithoutDish),
        });
      });
    });
  });

  describe('edit existing meal with dish having dish source relation, ', () => {
    // 既存のrelation情報を新しい値で更新するテストはEditDishで行っているので一旦割愛
    // バグったり必要になったときに改めて定義。
  });
});
