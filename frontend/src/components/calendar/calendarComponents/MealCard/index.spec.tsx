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
  PostponeMealDocument,
} from '../../../../lib/graphql/generated/graphql';
import { MEAL_TYPE } from '../../../../features/meal/const';

const buildMeal = (overrides = {}) => ({
  id: 10,
  date: new Date(2026, 2, 9),
  mealType: MEAL_TYPE.LUNCH,
  comment: null,
  mealFrameEntryId: null as number | null,
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
    it('昼食の場合、昼の印と text-lunch-foreground が適用され、root に背景色がないこと', () => {
      const meal = buildMeal({ mealType: MEAL_TYPE.LUNCH });
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      const mark = screen.getByText('昼');
      expect(mark).toHaveClass('text-lunch-foreground');
      const root = screen.getByTestId(`mealCard-${meal.id}`);
      expect(root).not.toHaveClass('bg-lunch-bg');
      expect(root).not.toHaveClass('border');
    });

    it('夕食の場合、夜の印と text-dinner-foreground が適用され、root に背景色がないこと', () => {
      const meal = buildMeal({ mealType: MEAL_TYPE.DINNER });
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      expect(screen.getByText('夜')).toHaveClass('text-dinner-foreground');
      expect(screen.getByTestId(`mealCard-${meal.id}`)).not.toHaveClass(
        'bg-dinner-bg',
      );
    });

    it('11文字以上のレシピ元が切り詰められず、ページが続くこと', () => {
      const meal = buildMeal({
        dish: {
          ...buildMeal().dish,
          dishSourceRelation: {
            type: 1,
            sourceName: 'オレンジページ2024年5月号',
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
      ).toHaveTextContent('オレンジページ2024年5月号 P42');
    });

    it('レシピ元が text-zinc-700 であること', () => {
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
      expect(screen.getByTestId(`mealCard-source-${meal.id}`)).toHaveClass(
        'text-zinc-700',
      );
    });

    it('食事コメントが薄くない text-muted-foreground であること', () => {
      const meal = buildMeal({ comment: '食事コメント' });
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      const el = screen.getByText('食事コメント');
      expect(el).toHaveClass('text-muted-foreground');
      expect(el).not.toHaveClass('text-muted-foreground/70');
    });

    it('コメントに line-clamp-2 と italic がないこと', () => {
      const meal = buildMeal({
        comment: '食事コメント',
        dish: { ...buildMeal().dish, comment: '料理コメント' },
      });
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      expect(screen.getByText('料理コメント')).not.toHaveClass('line-clamp-2');
      expect(screen.getByText('食事コメント')).not.toHaveClass('italic');
    });

    it('今日以外の日に「評価」のボタンがないこと', () => {
      renderWithApollo(<MealCard {...baseProps} meal={buildMeal()} />);
      expect(screen.queryByLabelText('評価')).not.toBeInTheDocument();
    });

    it('点数が text-amber-700 であること', () => {
      const meal = buildMeal({ dish: { ...buildMeal().dish, evaluationScore: 4 } });
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      expect(screen.getByTestId(`mealCard-evaluation-${meal.id}`)).toHaveClass(
        'text-amber-700',
      );
    });

    it('操作欄が rounded-lg bg-muted の面で、border-t がないこと', async () => {
      const meal = buildMeal();
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      await userEvent.click(screen.getByTestId(`mealCard-${meal.id}`));
      const panel = screen.getByText('削除').closest('.bg-muted') as HTMLElement;
      expect(panel).toHaveClass('rounded-lg');
      expect(panel).not.toHaveClass('border-t');
    });

    it('区分アイコンの上の余白が、今日以外は mt-[3px]、今日は mt-[7px] であること', () => {
      renderWithApollo(<MealCard {...baseProps} meal={buildMeal()} />);
      const outer = screen
        .getByTestId('mealCard-10')
        .querySelector('svg')!
        .closest('span.inline-flex') as HTMLElement;
      expect(outer).toHaveClass('mt-[3px]');
      expect(outer).not.toHaveClass('mt-[7px]');
    });

    it('今日の区分アイコンの上の余白が mt-[7px] であること', () => {
      renderWithApollo(<MealCard {...baseProps} meal={buildMeal()} isToday />);
      const outer = screen
        .getByTestId('mealCard-10')
        .querySelector('svg')!
        .closest('span.inline-flex') as HTMLElement;
      expect(outer).toHaveClass('mt-[7px]');
    });

    it('常時表示の「食事編集」のボタンがないこと', () => {
      renderWithApollo(<MealCard {...baseProps} meal={buildMeal()} />);
      expect(screen.queryByLabelText('食事編集')).not.toBeInTheDocument();
    });

    describe('今日の食事', () => {
      it('未評価なら「評価する」と出ること', () => {
        renderWithApollo(<MealCard {...baseProps} meal={buildMeal()} isToday />);
        expect(screen.getByLabelText('評価')).toHaveTextContent('評価する');
      });

      it('評価ボタンが線の面で、未評価なら星アイコンが付くこと', () => {
        renderWithApollo(<MealCard {...baseProps} meal={buildMeal()} isToday />);
        const btn = screen.getByLabelText('評価');
        expect(btn).toHaveClass('border');
        expect(btn).toHaveClass('bg-background');
        expect(btn.querySelector('svg')).not.toBeNull();
      });

      it('評価済みの評価ボタンに星アイコンがないこと', () => {
        const meal = buildMeal({
          dish: { ...buildMeal().dish, evaluationScore: 4 },
        });
        renderWithApollo(<MealCard {...baseProps} meal={meal} isToday />);
        expect(screen.getByLabelText('評価').querySelector('svg')).toBeNull();
      });

      it('評価済みなら「★{score} 評価を変更」と出ること', () => {
        const meal = buildMeal({
          dish: { ...buildMeal().dish, evaluationScore: 4 },
        });
        renderWithApollo(<MealCard {...baseProps} meal={meal} isToday />);
        expect(screen.getByLabelText('評価')).toHaveTextContent('★4 評価を変更');
      });

      it('料理名が text-xl font-bold であること', () => {
        renderWithApollo(<MealCard {...baseProps} meal={buildMeal()} isToday />);
        const name = screen.getByText('生姜焼き');
        expect(name).toHaveClass('text-xl');
        expect(name).toHaveClass('font-bold');
      });

      it('押すと評価モーダルが開き、操作欄は開かないこと', async () => {
        renderWithApollo(<MealCard {...baseProps} meal={buildMeal()} isToday />);
        await userEvent.click(screen.getByLabelText('評価'));
        expect(
          document.querySelectorAll('.star-floating-half-click-target').length,
        ).toBeGreaterThan(0);
        expect(screen.queryByText('削除')).not.toBeInTheDocument();
      });

      it('canAnythingExceptDisplayDishName=false のとき出ないこと', () => {
        renderWithApollo(
          <MealCard
            {...baseProps}
            meal={buildMeal()}
            isToday
            canAnythingExceptDisplayDishName={false}
          />,
        );
        expect(screen.queryByLabelText('評価')).not.toBeInTheDocument();
      });
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

    it('アクションパネルに「延期」ボタンが表示されること', async () => {
      const meal = buildMeal();
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);
      await userEvent.click(screen.getByTestId(`mealCard-${meal.id}`));
      expect(screen.getByText('延期')).toBeInTheDocument();
    });

    it('延期ボタンタップで確認ダイアログなしに postponeMeal mutation が呼ばれること', async () => {
      const meal = buildMeal();
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);

      const { getLatestMutationVariables } = registerMutationHandler(
        PostponeMealDocument,
        {
          postponeMeal: {
            postponedMealId: 999,
          },
        },
      );

      const confirmSpy = jest.spyOn(window, 'confirm');

      await userEvent.click(screen.getByLabelText('その他のアクション'));
      await userEvent.click(screen.getByText('延期'));

      expect(confirmSpy).not.toHaveBeenCalled();
      await waitFor(() => {
        expect(getLatestMutationVariables()).toEqual({ mealId: meal.id });
      });
    });

    it('延期ボタンタップでアクションパネルが閉じること', async () => {
      const meal = buildMeal();
      renderWithApollo(<MealCard {...baseProps} meal={meal} />);

      registerMutationHandler(PostponeMealDocument, {
        postponeMeal: {
          postponedMealId: 999,
        },
      });

      await userEvent.click(screen.getByLabelText('その他のアクション'));
      await userEvent.click(screen.getByText('延期'));

      expect(screen.queryByText('延期')).not.toBeInTheDocument();
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
        renderWithApollo(<MealCard {...baseProps} meal={meal} isToday />);
        await userEvent.click(screen.getByLabelText('評価'));
        const targets = document.querySelectorAll(
          '.star-floating-half-click-target',
        );
        await userEvent.click(targets[7] as Element);
        expect(document.querySelectorAll('i.fa-star.fas').length).toBe(4);
      });

      it('同じタップでアクション展開エリアが開かないこと', async () => {
        const meal = buildMeal();
        renderWithApollo(<MealCard {...baseProps} meal={meal} isToday />);
        await userEvent.click(screen.getByLabelText('評価'));
        const targets = document.querySelectorAll(
          '.star-floating-half-click-target',
        );
        await userEvent.click(targets[7] as Element);
        expect(screen.queryByText('名前コピー')).not.toBeInTheDocument();
      });

      it('親の無関係な再render後も選択スコアが保持されること', async () => {
        const user = userEvent.setup();
        const meal = buildMeal();

        const Parent = () => {
          const [tick, setTick] = React.useState(0);
          return (
            <div>
              <button
                type="button"
                data-testid="forceRerender"
                onClick={() => setTick(tick + 1)}
              >
                {`rerender-${tick}`}
              </button>
              <MealCard {...baseProps} meal={meal} isToday />
            </div>
          );
        };

        renderWithApollo(<Parent />);

        await user.click(screen.getByLabelText('評価'));
        const targets = document.querySelectorAll(
          '.star-floating-half-click-target',
        );
        await user.click(targets[7] as Element);
        expect(document.querySelectorAll('i.fa-star.fas').length).toBe(4);

        await user.click(screen.getByTestId('forceRerender'));

        expect(document.querySelectorAll('i.fa-star.fas').length).toBe(4);
      });
    });

    describe('名前コピー', () => {
      const setupClipboardMock = () => {
        const writeText = jest.fn();
        Object.defineProperty(navigator, 'clipboard', {
          value: { writeText },
          configurable: true,
        });
        return writeText;
      };

      it('レシピ元がある場合、「{sourceName}の{dish.name}」がコピーされること', async () => {
        const writeText = setupClipboardMock();
        const meal = buildMeal({
          dish: {
            ...buildMeal().dish,
            name: '肉じゃが',
            dishSourceRelation: {
              type: 1,
              sourceName: 'オレンジページ2024年5月号',
              dishSourceId: 1,
              recipeBookPage: 12,
              recipeWebsiteUrl: null,
              recipeSourceMemo: null,
            },
          },
        });
        renderWithApollo(<MealCard {...baseProps} meal={meal} />);
        await userEvent.click(screen.getByTestId(`mealCard-${meal.id}`));
        await userEvent.click(screen.getByText('名前コピー'));
        expect(writeText).toHaveBeenCalledWith(
          'オレンジページ2024年5月号の肉じゃが',
        );
      });

      it('レシピ元がない場合、「{dish.name}」がコピーされること', async () => {
        const writeText = setupClipboardMock();
        const meal = buildMeal({
          dish: {
            ...buildMeal().dish,
            name: 'カレー',
            dishSourceRelation: null,
          },
        });
        renderWithApollo(<MealCard {...baseProps} meal={meal} />);
        await userEvent.click(screen.getByTestId(`mealCard-${meal.id}`));
        await userEvent.click(screen.getByText('名前コピー'));
        expect(writeText).toHaveBeenCalledWith('カレー');
      });
    });
  });
});
