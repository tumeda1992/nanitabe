import React from 'react';
import '@testing-library/jest-dom';
import { fireEvent, screen, waitFor } from '@testing-library/react';
import { registerMutationHandler, registerQueryHandler } from '../../../../lib/graphql/specHelper/mockServer';
import { DishEffortLevelsDocument, UpdateDishDocument } from '../../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../../specHelper/renderWithApollo';
import EditDish from '../EditDish';
import { registeredDish, registerDishSourcesQuery } from './commonVariables';

const dishWithEffort = { ...registeredDish, dishEffortLevelId: 17 };

beforeEach(() => {
  registerDishSourcesQuery();
  registerQueryHandler(DishEffortLevelsDocument, {
    dishEffortLevels: [{ __typename: 'DishEffortLevel', id: 17, minutes: 20, label: '普通' }],
  });
});

it('restores the existing effort after the options finish loading', async () => {
  renderWithApollo(<React.StrictMode><EditDish dish={dishWithEffort} /></React.StrictMode>);
  expect(await screen.findByTestId('dishEffortLevelSelect')).toHaveValue('17');
});

it.each([
  ['unchanged', 17],
  ['name only', 17],
  ['explicit clear', null],
  ['meal position change', null],
])('submits the intended effort for %s', async (operation, expected) => {
  const { getLatestMutationVariables } = registerMutationHandler(UpdateDishDocument, { updateDish: { dishId: registeredDish.id } });
  renderWithApollo(<React.StrictMode><EditDish dish={dishWithEffort} /></React.StrictMode>);
  const select = await screen.findByTestId('dishEffortLevelSelect');
  if (operation === 'name only') fireEvent.change(screen.getByTestId('dishname'), { target: { value: 'renamed' } });
  if (operation === 'explicit clear') fireEvent.change(select, { target: { value: '' } });
  if (operation === 'meal position change') fireEvent.click(screen.getByTestId('mealPositionOption-1'));
  fireEvent.click(screen.getByTestId('submitDishButton'));
  await waitFor(() => expect(getLatestMutationVariables()).not.toBeNull());
  expect(getLatestMutationVariables().dish.dishEffortLevelId).toBe(expected);
});
