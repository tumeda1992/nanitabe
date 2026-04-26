import React from 'react';
import '@testing-library/jest-dom';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import FrameCard from './index';
import renderWithApollo from '../../../specHelper/renderWithApollo';
import {
  registerMutationHandler,
  registerQueryHandler,
} from '../../../../lib/graphql/specHelper/mockServer';
import {
  RemoveMealFrameEntryDocument,
  AddMealDocument,
  ExistingDishesForRegisteringWithMealDocument,
  DishSourcesDocument,
  DishEffortLevelsDocument,
  FillMealFrameEntryDocument,
} from '../../../../lib/graphql/generated/graphql';
import { MEAL_TYPE } from '../../../../features/meal/const';

const buildFrameEntry = (overrides = {}) => ({
  id: 1,
  mealFrameId: 10,
  mealFrameName: '週末枠',
  mealType: MEAL_TYPE.DINNER,
  ...overrides,
});

const buildMeal = (overrides = {}) => ({
  id: 100,
  date: new Date(2026, 2, 25),
  mealType: MEAL_TYPE.DINNER,
  comment: null,
  mealFrameEntryId: null,
  mealFrameName: null,
  dish: {
    id: 55,
    name: '生姜焼き',
    mealPosition: 2,
    comment: null,
    evaluationScore: null,
    dishSourceRelation: null,
    tags: null,
  },
  ...overrides,
});

const TEST_DATE = '2026-03-25';

describe('<FrameCard>', () => {
  describe('表示テスト', () => {
    it('枠名が表示されること', () => {
      const frameEntry = buildFrameEntry();
      renderWithApollo(
        <FrameCard frameEntry={frameEntry} onDeleted={jest.fn()} />,
      );
      expect(screen.getByText('週末枠')).toBeInTheDocument();
    });

    it('data-testid が設定されること', () => {
      const frameEntry = buildFrameEntry({ id: 5 });
      renderWithApollo(
        <FrameCard frameEntry={frameEntry} onDeleted={jest.fn()} />,
      );
      expect(screen.getByTestId('frameCard-5')).toBeInTheDocument();
    });

    it('削除ボタンが表示されること', () => {
      const frameEntry = buildFrameEntry();
      renderWithApollo(
        <FrameCard frameEntry={frameEntry} onDeleted={jest.fn()} />,
      );
      expect(screen.getByTestId('frameCard-deleteBtn-1')).toBeInTheDocument();
    });
  });

  describe('機能テスト', () => {
    it('削除ボタンタップで removeMealFrameEntry mutation が呼ばれること', async () => {
      const frameEntry = buildFrameEntry({ id: 3 });
      const onDeleted = jest.fn();
      renderWithApollo(
        <FrameCard frameEntry={frameEntry} onDeleted={onDeleted} />,
      );

      const { getLatestMutationVariables } = registerMutationHandler(
        RemoveMealFrameEntryDocument,
        {
          removeMealFrameEntry: {
            mealFrameEntryId: frameEntry.id,
          },
        },
      );

      window.confirm = jest.fn().mockReturnValue(true);

      await userEvent.click(screen.getByTestId('frameCard-deleteBtn-3'));

      await waitFor(() => {
        expect(getLatestMutationVariables()).toEqual({ id: frameEntry.id });
      });
    });

    it('削除確認キャンセルで mutation が呼ばれないこと', async () => {
      const frameEntry = buildFrameEntry({ id: 4 });
      renderWithApollo(
        <FrameCard frameEntry={frameEntry} onDeleted={jest.fn()} />,
      );

      window.confirm = jest.fn().mockReturnValue(false);
      let mutationCalled = false;

      registerMutationHandler(RemoveMealFrameEntryDocument, () => {
        mutationCalled = true;
        return { removeMealFrameEntry: { mealFrameEntryId: frameEntry.id } };
      });

      await userEvent.click(screen.getByTestId('frameCard-deleteBtn-4'));

      expect(mutationCalled).toBe(false);
    });

    describe('タブ切り替え', () => {
      it('Tab 1「新しく食事を登録」が表示されること', async () => {
        const frameEntry = buildFrameEntry({ id: 10 });
        renderWithApollo(
          <FrameCard
            frameEntry={frameEntry}
            unlinkedMeals={[]}
            onDeleted={jest.fn()}
            date={TEST_DATE}
          />,
        );
        await userEvent.click(screen.getByTestId('frameCard-10'));
        expect(screen.getByText('新しく食事を登録')).toBeInTheDocument();
      });

      it('unlinkedMeals がある場合 Tab 2「既存の食事を割り当て」が表示されること', async () => {
        const frameEntry = buildFrameEntry({ id: 11 });
        const meal = buildMeal({ id: 200 });
        renderWithApollo(
          <FrameCard
            frameEntry={frameEntry}
            unlinkedMeals={[meal]}
            onDeleted={jest.fn()}
            date={TEST_DATE}
          />,
        );
        await userEvent.click(screen.getByTestId('frameCard-11'));
        expect(screen.getByText('既存の食事を割り当て')).toBeInTheDocument();
      });

      it('「既存の食事を割り当て」タブクリックで食事リストが表示されること', async () => {
        const frameEntry = buildFrameEntry({ id: 12 });
        const meal = buildMeal({ id: 201 });
        renderWithApollo(
          <FrameCard
            frameEntry={frameEntry}
            unlinkedMeals={[meal]}
            onDeleted={jest.fn()}
            date={TEST_DATE}
          />,
        );
        await userEvent.click(screen.getByTestId('frameCard-12'));
        await userEvent.click(screen.getByText('既存の食事を割り当て'));
        expect(screen.getByText('生姜焼き')).toBeInTheDocument();
      });

      it('unlinkedMeals が空の場合「割り当て可能な食事がありません」が表示されること', async () => {
        const frameEntry = buildFrameEntry({ id: 13 });
        renderWithApollo(
          <FrameCard
            frameEntry={frameEntry}
            unlinkedMeals={[]}
            onDeleted={jest.fn()}
            date={TEST_DATE}
          />,
        );
        await userEvent.click(screen.getByTestId('frameCard-13'));
        await userEvent.click(screen.getByText('既存の食事を割り当て'));
        expect(screen.getByText('割り当て可能な食事がありません')).toBeInTheDocument();
      });

      it('食事を選択して「割り当てる」→ fillMealFrameEntry が呼ばれること', async () => {
        const frameEntry = buildFrameEntry({ id: 14 });
        const meal = buildMeal({ id: 202 });
        const onAddSucceeded = jest.fn();
        renderWithApollo(
          <FrameCard
            frameEntry={frameEntry}
            unlinkedMeals={[meal]}
            onDeleted={jest.fn()}
            onAddSucceeded={onAddSucceeded}
            date={TEST_DATE}
          />,
        );

        const { getLatestMutationVariables } = registerMutationHandler(
          FillMealFrameEntryDocument,
          {
            fillMealFrameEntry: {
              frameEntryId: frameEntry.id,
            },
          },
        );

        await userEvent.click(screen.getByTestId('frameCard-14'));
        await userEvent.click(screen.getByText('既存の食事を割り当て'));
        await userEvent.click(screen.getByText('生姜焼き'));

        await waitFor(() => {
          expect(getLatestMutationVariables()).toEqual({
            frameEntryId: frameEntry.id,
            mealId: meal.id,
          });
        });
      });
    });

    describe('クリックで AddMeal モーダルが開くこと', () => {
      const existingDishId = 55;

      beforeEach(() => {
        registerQueryHandler(DishEffortLevelsDocument, {
          dishEffortLevels: [],
        });
        registerQueryHandler(ExistingDishesForRegisteringWithMealDocument, {
          existingDishesForRegisteringWithMeal: [
            {
              __typename: 'Dish',
              id: existingDishId,
              name: '生姜焼き',
              mealPosition: 2,
              comment: null,
              dishSourceName: null,
              evaluationScore: null,
            },
          ],
        });
        registerQueryHandler(DishSourcesDocument, {
          dishSources: [],
        });
      });

      it('カードのクリックでモーダルが開くこと', async () => {
        const frameEntry = buildFrameEntry({ id: 5 });
        const onAddSucceeded = jest.fn();
        renderWithApollo(
          <FrameCard
            frameEntry={frameEntry}
            onDeleted={jest.fn()}
            onAddSucceeded={onAddSucceeded}
            date={TEST_DATE}
          />,
        );

        await userEvent.click(screen.getByTestId('frameCard-5'));

        expect(screen.getByTestId('addMealFormModal')).toBeInTheDocument();
      });

      it('date が AddMeal の日付フィールドに渡されること', async () => {
        const frameEntry = buildFrameEntry({ id: 7 });
        renderWithApollo(
          <FrameCard
            frameEntry={frameEntry}
            onDeleted={jest.fn()}
            date={TEST_DATE}
          />,
        );

        await userEvent.click(screen.getByTestId('frameCard-7'));

        const dateInput = screen.getByTestId('mealDate') as HTMLInputElement;
        expect(dateInput.value).toBe(TEST_DATE);
      });

      it('登録後に onAddSucceeded コールバックが呼ばれること', async () => {
        const frameEntry = buildFrameEntry({ id: 6 });
        const onAddSucceeded = jest.fn();
        renderWithApollo(
          <FrameCard
            frameEntry={frameEntry}
            onDeleted={jest.fn()}
            onAddSucceeded={onAddSucceeded}
          />,
        );

        const { mutationInterceptor } = registerMutationHandler(
          AddMealDocument,
          {
            addMeal: {
              mealId: 1,
            },
          },
        );

        await userEvent.click(screen.getByTestId('frameCard-6'));
        await userEvent.click(
          screen.getByTestId(`existingDish-${existingDishId}`),
        );
        await userEvent.click(screen.getByTestId('submitMealButton'));

        await waitFor(() =>
          expect(mutationInterceptor).toHaveBeenCalledTimes(1),
        );
        await waitFor(() => expect(onAddSucceeded).toHaveBeenCalledTimes(1));
      });
    });
  });
});
