import React from 'react';
import '@testing-library/jest-dom';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import FrameCard from './index';
import renderWithApollo from '../../../specHelper/renderWithApollo';
import { registerMutationHandler } from '../../../../lib/graphql/specHelper/mockServer';
import { RemoveMealFrameEntryDocument } from '../../../../lib/graphql/generated/graphql';
import { MEAL_TYPE } from '../../../../features/meal/const';

const buildFrameEntry = (overrides = {}) => ({
  id: 1,
  mealFrameId: 10,
  mealFrameName: '週末枠',
  mealType: MEAL_TYPE.DINNER,
  ...overrides,
});

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
  });
});
