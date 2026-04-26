import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import { registerQueryHandler } from '../../lib/graphql/specHelper/mockServer';
import { MealFramePatternsDocument } from '../../lib/graphql/generated/graphql';
import renderWithApollo from '../specHelper/renderWithApollo';
import MealFramePatternList from './MealFramePatternList';

const mockPatterns = [
  {
    __typename: 'MealFramePatternForList' as const,
    id: 1,
    name: '糖質オフ週',
    entries: [
      {
        __typename: 'MealFramePatternEntryForList' as const,
        id: 1,
        dayOffset: 1,
        mealType: 1,
        mealFrameId: 1,
        mealFrameName: '朝枠',
      },
      {
        __typename: 'MealFramePatternEntryForList' as const,
        id: 2,
        dayOffset: 2,
        mealType: 3,
        mealFrameId: 2,
        mealFrameName: '夜枠',
      },
    ],
  },
  {
    __typename: 'MealFramePatternForList' as const,
    id: 2,
    name: '3日魚中心',
    entries: [],
  },
];

describe('<MealFramePatternList>', () => {
  describe('パターン一覧表示', () => {
    beforeEach(() => {
      registerQueryHandler(MealFramePatternsDocument, {
        mealFramePatterns: mockPatterns,
      });
      renderWithApollo(
        <MealFramePatternList
          onEditPattern={() => {}}
          onDeletePattern={() => {}}
        />
      );
    });

    it('パターン名が表示される', async () => {
      expect(await screen.findByText('糖質オフ週')).toBeInTheDocument();
      expect(await screen.findByText('3日魚中心')).toBeInTheDocument();
    });

    it('各パターンに編集リンクと削除ボタンが表示される', async () => {
      expect(await screen.findByTestId('editPattern-1')).toBeInTheDocument();
      expect(await screen.findByTestId('deletePattern-1')).toBeInTheDocument();
      expect(await screen.findByTestId('editPattern-2')).toBeInTheDocument();
      expect(await screen.findByTestId('deletePattern-2')).toBeInTheDocument();
    });
  });

  describe('空の一覧', () => {
    beforeEach(() => {
      registerQueryHandler(MealFramePatternsDocument, {
        mealFramePatterns: [],
      });
      renderWithApollo(
        <MealFramePatternList
          onEditPattern={() => {}}
          onDeletePattern={() => {}}
        />
      );
    });

    it('パターンがない場合のメッセージが表示される', async () => {
      expect(await screen.findByText('パターンがまだ登録されていません。')).toBeInTheDocument();
    });
  });
});
