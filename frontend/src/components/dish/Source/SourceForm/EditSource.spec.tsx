import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import renderWithApollo from '../../../specHelper/renderWithApollo';
import { registerMutationHandler } from '../../../../lib/graphql/specHelper/mockServer';
import {
  userChooseSelectBox,
  userClick,
  userTypeAfterClearTextBox,
} from '../../../specHelper/userEvents';
import EditSource from './EditSource';
import { DISH_SOURCE_TYPE } from '../../../../features/dish/source/const';
import { UpdateDishSourceDocument } from '../../../../lib/graphql/generated/graphql';

describe('<EditSource>', () => {
  const registeredDishSource = {
    id: 1,
    name: 'りゅうじ',
    type: DISH_SOURCE_TYPE.WEBSITE,
  };

  const updatedDishSource = {
    id: 1,
    name: '新しいゆーちゅーばー',
    type: DISH_SOURCE_TYPE.YOUTUBE,
  };

  beforeEach(() => {
    renderWithApollo(
      <EditSource
        dishSource={registeredDishSource}
        onSchemaError={(schemaErrors) => {
          // スキーマエラーがあったときテストで把握しやすいようにログに出す
          console.log(schemaErrors);
        }}
      />,
    );
  });

  describe('when update dish source', () => {
    it('succeeds with expected graphql params', async () => {
      const { getLatestMutationVariables } = registerMutationHandler(
        UpdateDishSourceDocument,
        {
          updateDishSource: {
            dishSourceId: 1,
          },
        },
      );

      await userTypeAfterClearTextBox(
        screen,
        'dishSourceName',
        updatedDishSource.name,
      );
      await userChooseSelectBox(screen, 'dishSourceTypeOption', [
        `dishSourceTypeOption-${updatedDishSource.type}`,
      ]);

      await userClick(screen, 'submitDishSourceButton');

      expect(getLatestMutationVariables()).toEqual({
        dishSource: updatedDishSource,
      });
    });
  });
});
