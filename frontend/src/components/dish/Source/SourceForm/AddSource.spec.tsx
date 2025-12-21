import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import renderWithApollo from '../../../specHelper/renderWithApollo';
import { registerMutationHandler } from '../../../../lib/graphql/specHelper/mockServer';
import AddSource from './AddSource';
import { DISH_SOURCE_TYPE } from '../../../../features/dish/source/const';
import { AddDishSourceDocument } from '../../../../lib/graphql/generated/graphql';
import {
  userChooseSelectBox,
  userClick,
  userType,
} from '../../../specHelper/userEvents';

describe('<AddSource>', () => {
  const newDishSourceWithRequiredParams = {
    name: 'はじめての中華料理',
    type: DISH_SOURCE_TYPE.RECIPE_BOOK,
  };

  beforeEach(() => {
    renderWithApollo(
      <AddSource
        onSchemaError={(schemaErrors) => {
          // スキーマエラーがあったときテストで把握しやすいようにログに出す
          console.log(schemaErrors);
        }}
      />,
    );
  });

  describe('when add dish source', () => {
    it('succeeds with expected graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        AddDishSourceDocument,
        {
          addDishSource: {
            dishSourceId: 1,
          },
        },
      );

      await userType(
        screen,
        'dishSourceName',
        newDishSourceWithRequiredParams.name,
      );
      await userChooseSelectBox(screen, 'dishSourceTypeOption', [
        `dishSourceTypeOption-${newDishSourceWithRequiredParams.type}`,
      ]);
      await userClick(screen, 'submitDishSourceButton');

      expect(getLatestMutationVariables()).toEqual({
        dishSource: newDishSourceWithRequiredParams,
      });
    });
  });
});
