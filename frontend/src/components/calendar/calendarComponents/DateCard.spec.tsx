import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import DateCard from './DateCard';
import renderWithApollo from '../../specHelper/renderWithApollo';
import { registerQueryHandler } from '../../../lib/graphql/specHelper/mockServer';
import {
  DishEffortLevelsDocument,
  ExistingDishesForRegisteringWithMealDocument,
  DishSourcesDocument,
  MealFramesDocument,
  MealFramePatternsDocument,
} from '../../../lib/graphql/generated/graphql';

const buildMeal = (overrides = {}) => ({
  id: 1,
  date: new Date(2026, 2, 9),
  mealType: 3,
  comment: null,
  dish: {
    id: 10,
    name: '生姜焼き',
    mealPosition: 2,
    comment: null,
    evaluationScore: null,
    dishSourceRelation: null,
    tags: null,
  },
  ...overrides,
});

const buildFrameEntry = (overrides = {}) => ({
  id: 1,
  mealFrameId: 10,
  mealFrameName: '週末枠',
  mealType: 3,
  ...overrides,
});

const baseProps = {
  date: new Date(2026, 2, 9), // 2026-03-09 (Monday)
  dayLabel: '月',
  meals: [],
  frameEntries: [],
  isDisplayCalendarMode: true,
  calendarModeChangers: { startMovingDishMode: jest.fn() },
  onChanged: jest.fn().mockResolvedValue(undefined),
  startSwappingMealsMode: jest.fn(),
};

describe('<DateCard>', () => {
  describe('表示テスト', () => {
    it('今日の日付にハイライトクラスが付くこと', () => {
      const today = new Date();
      renderWithApollo(<DateCard {...baseProps} date={today} />);
      expect(screen.getByTestId('dateCard-card')).toHaveAttribute(
        'data-today',
        'true',
      );
    });

    it('今日でない日付にハイライトクラスが付かないこと', () => {
      const notToday = new Date(2000, 0, 1);
      renderWithApollo(<DateCard {...baseProps} date={notToday} />);
      expect(screen.getByTestId('dateCard-card')).toHaveAttribute(
        'data-today',
        'false',
      );
    });

    it('土曜日に青色クラスが付くこと', () => {
      const saturday = new Date(2026, 2, 7); // 2026-03-07 is Saturday
      renderWithApollo(<DateCard {...baseProps} date={saturday} dayLabel="土" />);
      // 日付番号に青色クラスが付くこと
      const dateText = screen.getByText('7');
      expect(dateText).toHaveClass('text-blue-500');
    });

    it('日曜日に赤色クラスが付くこと', () => {
      const sunday = new Date(2026, 2, 8); // 2026-03-08 is Sunday
      renderWithApollo(<DateCard {...baseProps} date={sunday} dayLabel="日" />);
      const dateText = screen.getByText('8');
      expect(dateText).toHaveClass('text-red-500');
    });

    it('料理名が表示されること', () => {
      const meals = [buildMeal()];
      renderWithApollo(<DateCard {...baseProps} meals={meals} />);
      expect(screen.getByText('生姜焼き')).toBeInTheDocument();
    });

    it('isDisplayCalendarMode=true のとき + ボタンが表示されること', () => {
      renderWithApollo(<DateCard {...baseProps} isDisplayCalendarMode={true} />);
      expect(screen.getByTestId('dateCard-addMeal')).toBeInTheDocument();
    });

    it('isDisplayCalendarMode=false のとき + ボタンが表示されないこと', () => {
      renderWithApollo(
        <DateCard {...baseProps} isDisplayCalendarMode={false} />,
      );
      expect(screen.queryByTestId('dateCard-addMeal')).not.toBeInTheDocument();
    });

    it('meals が空 かつ isDisplayCalendarMode=true のとき点線の追加エリアが表示されること', () => {
      renderWithApollo(
        <DateCard {...baseProps} meals={[]} isDisplayCalendarMode={true} />,
      );
      expect(screen.getByTestId('dateCard-emptyMealArea')).toBeInTheDocument();
    });

    it('meals が存在するとき点線の追加エリアが表示されないこと', () => {
      const meals = [buildMeal()];
      renderWithApollo(
        <DateCard {...baseProps} meals={meals} isDisplayCalendarMode={true} />,
      );
      expect(
        screen.queryByTestId('dateCard-emptyMealArea'),
      ).not.toBeInTheDocument();
    });

    it('frameEntries が存在するとき枠名が表示されること', () => {
      const frameEntries = [buildFrameEntry({ mealFrameName: '週末枠' })];
      renderWithApollo(
        <DateCard {...baseProps} frameEntries={frameEntries} />,
      );
      expect(screen.getByText('週末枠')).toBeInTheDocument();
    });

    it('frameEntries が空のとき枠カードが表示されないこと', () => {
      renderWithApollo(
        <DateCard {...baseProps} frameEntries={[]} />,
      );
      expect(screen.queryByTestId('frameCard-1')).not.toBeInTheDocument();
    });
  });

  describe('機能テスト', () => {
    it('空エリアをクリックすると食事登録モーダルが開くこと', async () => {
      registerQueryHandler(DishEffortLevelsDocument, { dishEffortLevels: [] });
      registerQueryHandler(ExistingDishesForRegisteringWithMealDocument, {
        existingDishesForRegisteringWithMeal: [],
      });
      registerQueryHandler(DishSourcesDocument, { dishSources: [] });
      registerQueryHandler(MealFramesDocument, { mealFrames: [] });
      registerQueryHandler(MealFramePatternsDocument, { mealFramePatterns: [] });

      renderWithApollo(
        <DateCard {...baseProps} meals={[]} isDisplayCalendarMode={true} />,
      );

      await userEvent.click(screen.getByTestId('dateCard-emptyMealArea'));

      expect(screen.getByTestId('dateCard-emptyMealAreaModal')).toBeInTheDocument();
    });

    it('空エリアをクリックすると3タブ（食事/枠/枠パターン適用）モーダルが開くこと', async () => {
      registerQueryHandler(DishEffortLevelsDocument, { dishEffortLevels: [] });
      registerQueryHandler(ExistingDishesForRegisteringWithMealDocument, {
        existingDishesForRegisteringWithMeal: [],
      });
      registerQueryHandler(DishSourcesDocument, { dishSources: [] });
      registerQueryHandler(MealFramesDocument, { mealFrames: [] });
      registerQueryHandler(MealFramePatternsDocument, { mealFramePatterns: [] });

      renderWithApollo(
        <DateCard {...baseProps} meals={[]} isDisplayCalendarMode={true} />,
      );

      await userEvent.click(screen.getByTestId('dateCard-emptyMealArea'));

      expect(screen.getByTestId('addTypeMeal')).toBeInTheDocument();
      expect(screen.getByTestId('addTypeFrame')).toBeInTheDocument();
      expect(screen.getByTestId('addTypePattern')).toBeInTheDocument();
    });

    it('日付ヘッダーをクリックすると startSwappingMealsMode が該当 date を引数に呼ばれること', async () => {
      const startSwappingMealsMode = jest.fn();
      const date = new Date(2026, 2, 9);
      renderWithApollo(
        <DateCard
          {...baseProps}
          date={date}
          startSwappingMealsMode={startSwappingMealsMode}
        />,
      );
      await userEvent.click(screen.getByTestId('dateCard-dateHeader'));
      expect(startSwappingMealsMode).toHaveBeenCalledWith(date);
    });

    it('meals が存在するとき CalendarMealIcon が meal の数だけレンダリングされること', () => {
      const meals = [buildMeal({ id: 1 }), buildMeal({ id: 2, dish: { ...buildMeal().dish, name: 'カレー' } })];
      renderWithApollo(<DateCard {...baseProps} meals={meals} />);
      expect(screen.getByText('生姜焼き')).toBeInTheDocument();
      expect(screen.getByText('カレー')).toBeInTheDocument();
    });
  });
});
