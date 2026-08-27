import React from 'react';
import '@testing-library/jest-dom';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import MealCard from './index';
import renderWithApollo from '../../../specHelper/renderWithApollo';
import { registerMutationHandler } from '../../../../lib/graphql/specHelper/mockServer';
import {
  RemoveMealDocument,
  UnassignMealFromFrameEntryDocument,
} from '../../../../lib/graphql/generated/graphql';
import { MEAL_TYPE } from '../../../../features/meal/const';

const buildMeal = (overrides = {}) => ({
  id: 10,
  date: new Date(2026, 2, 9),
  mealType: MEAL_TYPE.LUNCH,
  comment: null,
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

const baseProps = {
  onChanged: jest.fn().mockResolvedValue(undefined),
  canAnythingExceptDisplayDishName: true,
  calendarModeChangers: { startMovingDishMode: jest.fn() },
  startSwappingMealsMode: jest.fn(),
};

describe('<MealCard>', () => {
  describe('表示テスト', () => {
    it('昼食の場合 bg-lunch-bg クラスが適用されること', () => {
      const meal = buildMeal({ mealType: MEAL_TYPE.LUNCH });
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      expect(screen.getByTestId(`mealCard-${meal.id}`)).toHaveClass(
        'bg-lunch-bg',
      );
    });

    it('夕食の場合 bg-dinner-bg クラスが適用されること', () => {
      const meal = buildMeal({ mealType: MEAL_TYPE.DINNER });
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      expect(screen.getByTestId(`mealCard-${meal.id}`)).toHaveClass(
        'bg-dinner-bg',
      );
    });

    it('料理名が表示されること', () => {
      const meal = buildMeal();
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      expect(screen.getByText('生姜焼き')).toBeInTheDocument();
    });

    it('dish.evaluationScore がある場合に評価が表示されること', () => {
      const meal = buildMeal({
        dish: { ...buildMeal().dish, evaluationScore: 4 },
      });
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      expect(
        screen.getByTestId(`mealCard-evaluation-${meal.id}`),
      ).toBeInTheDocument();
      expect(screen.getByTestId(`mealCard-evaluation-${meal.id}`)).toHaveTextContent('4');
    });

    it('dish.dishSourceRelation.sourceName がある場合にレシピ元が表示されること', () => {
      const meal = buildMeal({
        dish: {
          ...buildMeal().dish,
          dishSourceRelation: {
            type: 1,
            sourceName: 'きょうの料理',
            dishSourceId: 1,
            recipeBookPage: 42,
            recipeWebsiteUrl: null,
            recipeSourceMemo: null,
          },
        },
      });
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      expect(
        screen.getByTestId(`mealCard-source-${meal.id}`),
      ).toBeInTheDocument();
    });

    it('meal.mealFrameName がある場合に枠名ラベルが表示されること', () => {
      const meal = buildMeal({ mealFrameName: 'パスタ枠' });
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      expect(screen.getByTestId(`mealCard-frameName-${meal.id}`)).toBeInTheDocument();
      expect(screen.getByTestId(`mealCard-frameName-${meal.id}`)).toHaveTextContent('パスタ枠');
    });

    it('meal.mealFrameName がある場合に枠名ラベルが料理名の前（上）にあること', () => {
      const meal = buildMeal({ mealFrameName: 'パスタ枠' });
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      const frameLabel = screen.getByTestId(`mealCard-frameName-${meal.id}`);
      const dishName = screen.getByText('生姜焼き');
      // DOMの順序確認: fremeLabel が dishName より前にあること
      const position = frameLabel.compareDocumentPosition(dishName);
      // DOCUMENT_POSITION_FOLLOWING = 4 (dishName が frameLabel の後にある)
      expect(position & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    });

    it('meal.mealFrameName がない場合に枠名ラベルが表示されないこと', () => {
      const meal = buildMeal({ mealFrameName: null });
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      expect(screen.queryByTestId(`mealCard-frameName-${meal.id}`)).not.toBeInTheDocument();
    });

    it('canAnythingExceptDisplayDishName=false のとき MoreHorizontal が表示されないこと', () => {
      const meal = buildMeal();
      renderWithApollo(
        <MealCard
          {...baseProps}
          meal={meal}
          canAnythingExceptDisplayDishName={false}
        />,
      );
      expect(
        screen.queryByLabelText('その他のアクション'),
      ).not.toBeInTheDocument();
    });
  });

  describe('機能テスト', () => {
    it('カード本体クリックでアクションパネルが表示されること', async () => {
      const meal = buildMeal();
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      await userEvent.click(screen.getByTestId(`mealCard-${meal.id}`));
      expect(screen.getByText('削除')).toBeInTheDocument();
    });

    it('カード本体をもう一度クリックしてもアクションパネルが閉じないこと', async () => {
      const meal = buildMeal();
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      await userEvent.click(screen.getByTestId(`mealCard-${meal.id}`));
      expect(screen.getByText('削除')).toBeInTheDocument();
      await userEvent.click(screen.getByTestId(`mealCard-${meal.id}`));
      // カード本体クリックは開くのみ（閉じない）
      expect(screen.getByText('削除')).toBeInTheDocument();
    });

    it('MoreHorizontal タップでアクションパネルが表示されること', async () => {
      const meal = buildMeal();
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      await userEvent.click(screen.getByLabelText('その他のアクション'));
      expect(screen.getByText('削除')).toBeInTheDocument();
    });

    it('もう一度タップでアクションパネルが閉じること', async () => {
      const meal = buildMeal();
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      await userEvent.click(screen.getByLabelText('その他のアクション'));
      expect(screen.getByText('削除')).toBeInTheDocument();
      await userEvent.click(screen.getByLabelText('その他のアクション'));
      expect(screen.queryByText('削除')).not.toBeInTheDocument();
    });

    it('削除ボタンタップで removeMeal mutation が呼ばれること', async () => {
      const meal = buildMeal();
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);

      const { getLatestMutationVariables } = registerMutationHandler(
        RemoveMealDocument,
        {
          removeMeal: {
            mealId: meal.id,
          },
        },
      );

      window.confirm = jest.fn().mockReturnValue(true);

      await userEvent.click(screen.getByLabelText('その他のアクション'));
      await userEvent.click(screen.getByText('削除'));

      await waitFor(() => {
        expect(getLatestMutationVariables()).toEqual({ mealId: meal.id });
      });
    });

    it('「他の日へ移動」タップで startMovingDishMode が呼ばれること', async () => {
      const startMovingDishMode = jest.fn();
      const meal = buildMeal();
      renderWithApollo(
        <MealCard
          {...baseProps}
          meal={meal}
          calendarModeChangers={{ startMovingDishMode }}
        />,
      );
      await userEvent.click(screen.getByLabelText('その他のアクション'));
      await userEvent.click(screen.getByText('他の日へ'));
      expect(startMovingDishMode).toHaveBeenCalledWith(meal);
    });

    it('「日付交換」タップで startSwappingMealsMode が呼ばれること', async () => {
      const startSwappingMealsMode = jest.fn();
      const meal = buildMeal();
      renderWithApollo(
        <MealCard
          {...baseProps}
          meal={meal}
          startSwappingMealsMode={startSwappingMealsMode}
        />,
      );
      await userEvent.click(screen.getByLabelText('その他のアクション'));
      await userEvent.click(screen.getByText('日付交換'));
      expect(startSwappingMealsMode).toHaveBeenCalled();
    });

    describe('枠解除ボタン', () => {
      it('mealFrameEntryId がある場合は「枠解除」ボタンが表示されること', async () => {
        const meal = buildMeal({ mealFrameEntryId: 5 });
        renderWithApollo(<MealCard {...baseProps} meal={meal} />);
        await userEvent.click(screen.getByTestId(`mealCard-${meal.id}`));
        expect(screen.getByText('枠解除')).toBeInTheDocument();
      });

      it('mealFrameEntryId がない場合は「枠解除」ボタンが表示されないこと', async () => {
        const meal = buildMeal({ mealFrameEntryId: null });
        renderWithApollo(<MealCard {...baseProps} meal={meal} />);
        await userEvent.click(screen.getByTestId(`mealCard-${meal.id}`));
        expect(screen.queryByText('枠解除')).not.toBeInTheDocument();
      });

      it('「枠解除」クリック → confirm → unassignMealFromFrameEntry が呼ばれること', async () => {
        const meal = buildMeal({ mealFrameEntryId: 5 });
        renderWithApollo(<MealCard {...baseProps} meal={meal} />);

        const { getLatestMutationVariables } = registerMutationHandler(
          UnassignMealFromFrameEntryDocument,
          {
            unassignMealFromFrameEntry: {
              frameEntryId: meal.mealFrameEntryId,
            },
          },
        );

        window.confirm = jest.fn().mockReturnValue(true);

        await userEvent.click(screen.getByTestId(`mealCard-${meal.id}`));
        await userEvent.click(screen.getByText('枠解除'));

        await waitFor(() => {
          expect(getLatestMutationVariables()).toEqual({
            frameEntryId: meal.mealFrameEntryId,
          });
        });
      });
    });

    describe('評価モーダルの★タップ', () => {
      it('★4右半分を1回タップすると塗られた星が4になること', async () => {
        const meal = buildMeal();
        renderWithApollo(<MealCard {...baseProps} meal={meal} />);
        await userEvent.click(screen.getByLabelText('評価'));
        const targets = document.querySelectorAll(
          '.star-floating-half-click-target',
        );
        await userEvent.click(targets[7] as Element);
        expect(document.querySelectorAll('i.fa-star.fas').length).toBe(4);
      });

      it('同じタップでアクション展開エリアが開かないこと', async () => {
        const meal = buildMeal();
        renderWithApollo(<MealCard {...baseProps} meal={meal} />);
        await userEvent.click(screen.getByLabelText('評価'));
        const targets = document.querySelectorAll(
          '.star-floating-half-click-target',
        );
        await userEvent.click(targets[7] as Element);
        expect(screen.queryByText('名前コピー')).not.toBeInTheDocument();
      });

    });

  });
});
