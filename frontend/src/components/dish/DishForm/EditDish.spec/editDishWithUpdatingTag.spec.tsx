import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import {
  registerMutationHandler,
} from '../../../../lib/graphql/specHelper/mockServer';
import {
  UpdateDishDocument,
  UpdateDishWithNewSourceDocument,
} from '../../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../../specHelper/renderWithApollo';
import EditDish from '../EditDish';
import {
  userClearTextbox,
  userClick,
  userType,
  userChooseSelectBox,
  userTypeAfterClearTextBox,
} from '../../../specHelper/userEvents';
import { 
  registeredDish,
  updatedDish,
  newDishSourceRelationDetailOfRecipeWebsite,
  newDishSource,
  registerDishSourcesQuery,
} from './commonVariables';

const newDishTag = {
  content: '白ワインに合う',
};

beforeEach(() => {
  registerDishSourcesQuery();
});

describe('<EditDish>', () => {
  describe('edit existing dish updating tag, ', () => {
    describe('when update with new tag', () => {
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

      it('succeeds with expected graphql params', async () => {
        const { getLatestMutationVariables } = registerMutationHandler(
          UpdateDishDocument,
          {
            updateDish: {
              dishId: 1,
            },
          },
        );

        await userClearTextbox(screen, 'dishname');
        await userType(screen, 'dishname', updatedDish.name);

        await userClick(screen, 'appendDishTag');
        await userType(screen, 'newDishTag-0', newDishTag.content);
  
        await userClick(screen, 'submitDishButton');

        expect(getLatestMutationVariables()).toEqual({
          dish: {
            ...registeredDish,
            name: updatedDish.name,
          },
          dishSourceRelation: null,
          dishTags: [
            { content: newDishTag.content }
          ],
        });
      });
    });

    describe('when update dish with new source relation and new tag', () => {
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

        await userClick(screen, 'appendDishTag');
        await userType(screen, 'newDishTag-0', newDishTag.content);

        await userClick(screen, 'submitDishButton');

        expect(getLatestMutationVariables()).toEqual({
          dish: {
            ...registeredDish,
          },
          dishSource: newDishSource,
          dishSourceRelationDetail:
            newDishSourceRelationDetailOfRecipeWebsite,
          dishTags: [
            { content: newDishTag.content }
          ],
        });
      });
    });

    describe('when update update with removing tag', () => {
      beforeEach(() => {
        const registeredDishWithOneTag = {
          ...registeredDish,
          tags: [
            { id: 1, content: newDishTag.content },
          ]
        };

        renderWithApollo(
          <EditDish
            dish={registeredDishWithOneTag}
            onSchemaError={(schemaErrors) => {
              console.log('入力値バリデーションエラー');
              // スキーマエラーがあったときテストで把握しやすいようにログに出す
              console.log(schemaErrors);
              // screen.debug();
            }}
          />,
        );
      });
      
      it('succeeds with expected graphql params', async () => {
        const { getLatestMutationVariables } = registerMutationHandler(
          UpdateDishDocument,
          {
            updateDish: {
              dishId: 1,
            },
          },
        );

        await userClearTextbox(screen, 'dishname');
        await userType(screen, 'dishname', updatedDish.name);

        await userType(screen, 'removeDishTag-0', newDishTag.content);
  
        await userClick(screen, 'submitDishButton');

        expect(getLatestMutationVariables()).toEqual({
          dish: {
            ...registeredDish,
            name: updatedDish.name,
          },
          dishSourceRelation: null,
          dishTags: [],
        });
      });
    });
  });

  describe('when update update with removing existing tag and appending new tag', () => {
    const existingTag1 = {id: 4, content: '1個目のターグ'};
    const existingTag2 = {id: 7, content: '2個目のたぐんちゅ'};
    const registeredDishWithTwoTag = {
      ...registeredDish,
      tags: [existingTag1, existingTag2]
    };

    beforeEach(() => {
      renderWithApollo(
        <EditDish
          dish={registeredDishWithTwoTag}
          onSchemaError={(schemaErrors) => {
            console.log('入力値バリデーションエラー');
            // スキーマエラーがあったときテストで把握しやすいようにログに出す
            console.log(schemaErrors);
            // screen.debug();
          }}
        />,
      );
    });
    
    it('succeeds with expected graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        UpdateDishDocument,
        {
          updateDish: {
            dishId: 1,
          },
        },
      );

      await userClearTextbox(screen, 'dishname');
      await userType(screen, 'dishname', updatedDish.name);

      await userClick(screen, 'appendDishTag');
      await userType(screen, 'newDishTag-2', newDishTag.content);

      await userType(screen, 'removeDishTag-0', newDishTag.content);

      await userClick(screen, 'submitDishButton');

      expect(getLatestMutationVariables()).toEqual({
        dish: {
          ...registeredDish,
          name: updatedDish.name,
        },
        dishSourceRelation: null,
        dishTags: [
          existingTag2,
          { content: newDishTag.content },
        ],
      });
    });
  });
});