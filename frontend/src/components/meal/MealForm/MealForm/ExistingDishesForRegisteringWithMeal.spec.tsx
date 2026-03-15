import React from 'react';
import '@testing-library/jest-dom';
import { screen, fireEvent } from '@testing-library/react';
import { useForm, FormProvider } from 'react-hook-form';
import {
  registerQueryHandler,
} from '../../../../lib/graphql/specHelper/mockServer';
import { ExistingDishesForRegisteringWithMealDocument } from '../../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../../specHelper/renderWithApollo';
import { ExistingDishesForRegisteringWithMeal } from './ExistingDishesForRegisteringWithMeal';

const registeredDish = {
  __typename: 'Dish' as const,
  id: 1,
  name: 'ハンバーグ',
  mealPosition: 2,
  comment: null,
  dishSourceName: null,
  evaluationScore: null,
};

const Wrapper = ({
  onNewDishIconForSelectClick,
  displayNewDishIconForSelect = false,
  dishIdRegisteredWithMeal,
}: {
  onNewDishIconForSelectClick?: (s: string) => void;
  displayNewDishIconForSelect?: boolean;
  dishIdRegisteredWithMeal?: number;
}) => {
  const methods = useForm({ defaultValues: { dishId: null } });
  return (
    <FormProvider {...methods}>
      <ExistingDishesForRegisteringWithMeal
        displayNewDishIconForSelect={displayNewDishIconForSelect}
        onNewDishIconForSelectClick={onNewDishIconForSelectClick}
        dishIdRegisteredWithMeal={dishIdRegisteredWithMeal}
      />
    </FormProvider>
  );
};

describe('<ExistingDishesForRegisteringWithMeal>', () => {
  beforeEach(() => {
    registerQueryHandler(ExistingDishesForRegisteringWithMealDocument, {
      existingDishesForRegisteringWithMeal: [registeredDish],
    });
  });

  describe('deselect', () => {
    it('deselects a dish when tapping the selected dish again', async () => {
      renderWithApollo(
        <Wrapper dishIdRegisteredWithMeal={undefined} />,
      );

      // 料理カードが表示されるまで待つ
      const dishCard = await screen.findByTestId(`existingDish-${registeredDish.id}`);

      // 最初はクラスが bg-primary/5 でない
      expect(dishCard.className).not.toContain('bg-primary/5');

      // 1回クリック → 選択される
      fireEvent.click(dishCard);
      expect(dishCard.className).toContain('bg-primary/5');

      // 2回クリック → 選択解除される
      fireEvent.click(dishCard);
      expect(dishCard.className).not.toContain('bg-primary/5');
    });
  });

  describe('searchString passing to onNewDishIconForSelectClick', () => {
    it('passes current searchString to onNewDishIconForSelectClick', async () => {
      const onNewDishIconForSelectClick = jest.fn();
      renderWithApollo(
        <Wrapper
          displayNewDishIconForSelect={true}
          onNewDishIconForSelectClick={onNewDishIconForSelectClick}
        />,
      );

      // 新規料理登録ボタンを押す（searchString は空のまま）
      const newDishButton = await screen.findByTestId('existingDish-new');
      fireEvent.click(newDishButton);

      expect(onNewDishIconForSelectClick).toHaveBeenCalledWith('');
    });
  });
});
