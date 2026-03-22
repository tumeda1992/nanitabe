import React from 'react';
import '@testing-library/jest-dom';
import { screen, waitFor } from '@testing-library/react';
import {
  registerQueryHandler,
  registerMutationHandler,
} from '../../../../../lib/graphql/specHelper/mockServer';
import {
  MealFramesDocument,
  AddMealFrameEntryDocument,
  AddMealFrameDocument,
} from '../../../../../lib/graphql/generated/graphql';
import renderWithApollo from '../../../../specHelper/renderWithApollo';
import AddMealFrame from './index';
import { userChooseSelectBox, userClick } from '../../../../specHelper/userEvents';
import userEvent from '@testing-library/user-event';

describe('<AddMealFrame>', () => {
  const dateForAdd = new Date('2026-03-21T09:00:00');

  beforeEach(() => {
    registerQueryHandler(MealFramesDocument, {
      mealFrames: [
        { __typename: 'MealFrameForList', id: 1, name: '週末枠' },
        { __typename: 'MealFrameForList', id: 2, name: '平日枠' },
      ],
    });
  });

  describe('登録フォーム', () => {
    it('枠選択セレクトボックスが表示される', async () => {
      renderWithApollo(
        <AddMealFrame dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      expect(await screen.findByTestId('mealFrameSelect')).toBeInTheDocument();
      expect(await screen.findByTestId('mealFrameOption-1')).toBeInTheDocument();
      expect(await screen.findByTestId('mealFrameOption-2')).toBeInTheDocument();
    });

    it('食事タイプがラジオボタンで表示される', async () => {
      renderWithApollo(
        <AddMealFrame dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      expect(await screen.findByTestId('mealTypeRadio-1')).toBeInTheDocument();
      expect(await screen.findByTestId('mealTypeRadio-2')).toBeInTheDocument();
      expect(await screen.findByTestId('mealTypeRadio-3')).toBeInTheDocument();
    });

    it('夕食がデフォルト選択されていること', async () => {
      renderWithApollo(
        <AddMealFrame dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      const dinnerRadio = await screen.findByTestId('mealTypeRadio-3') as HTMLInputElement;
      expect(dinnerRadio.checked).toBe(true);
    });

    it('枠と食事タイプを選択して登録ボタンをクリックするとaddMealFrameEntryが呼ばれる', async () => {
      const { mutationInterceptor } = registerMutationHandler(
        AddMealFrameEntryDocument,
        {
          addMealFrameEntry: {
            mealFrameEntryId: 1,
          },
        },
      );

      renderWithApollo(
        <AddMealFrame dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      await userChooseSelectBox(screen, 'mealFrameSelect', ['mealFrameOption-1']);
      // 夕食はデフォルト選択済みのため、そのまま登録
      await userClick(screen, 'submitAddMealFrameButton');

      expect(mutationInterceptor).toHaveBeenCalled();
    });

    it('枠選択に「新規作成...」が表示されること', async () => {
      renderWithApollo(
        <AddMealFrame dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      expect(await screen.findByTestId('mealFrameNewOption')).toBeInTheDocument();
    });
  });

  describe('新規枠作成フロー', () => {
    it('「新規作成...」を選択するとテキスト入力欄が表示されること', async () => {
      renderWithApollo(
        <AddMealFrame dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      await userChooseSelectBox(screen, 'mealFrameSelect', ['mealFrameNewOption']);

      expect(await screen.findByTestId('newMealFrameNameInput')).toBeInTheDocument();
    });

    it('テキスト入力後に確定ボタンをクリックするとaddMealFrameが呼ばれ、作成した枠が自動選択されること', async () => {
      const newMealFrameId = 99;

      const { mutationInterceptor: addMealFrameInterceptor } = registerMutationHandler(
        AddMealFrameDocument,
        {
          addMealFrame: {
            mealFrameId: newMealFrameId,
          },
        },
      );

      renderWithApollo(
        <AddMealFrame dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      await userChooseSelectBox(screen, 'mealFrameSelect', ['mealFrameNewOption']);
      await userEvent.type(screen.getByTestId('newMealFrameNameInput'), '新しい枠');
      await userClick(screen, 'confirmNewMealFrameButton');

      await waitFor(() => expect(addMealFrameInterceptor).toHaveBeenCalledTimes(1));

      // 新規作成後に入力欄が消えること
      await waitFor(() => {
        expect(screen.queryByTestId('newMealFrameNameInput')).not.toBeInTheDocument();
      });
    });

    it('新規作成後に枠一覧クエリが再取得されること', async () => {
      const newMealFrameId = 99;

      registerMutationHandler(AddMealFrameDocument, {
        addMealFrame: {
          mealFrameId: newMealFrameId,
        },
      });

      const { queryInterceptor: mealFramesQueryInterceptor } = registerQueryHandler(
        MealFramesDocument,
        {
          mealFrames: [
            { __typename: 'MealFrameForList', id: 1, name: '週末枠' },
            { __typename: 'MealFrameForList', id: 2, name: '平日枠' },
          ],
        },
      );

      renderWithApollo(
        <AddMealFrame dateForAdd={dateForAdd} onAddSucceeded={() => {}} />,
      );

      // 初回クエリが呼ばれるまで待つ
      await waitFor(() => expect(mealFramesQueryInterceptor).toHaveBeenCalledTimes(1));

      await userChooseSelectBox(screen, 'mealFrameSelect', ['mealFrameNewOption']);
      await userEvent.type(screen.getByTestId('newMealFrameNameInput'), '新しい枠');
      await userClick(screen, 'confirmNewMealFrameButton');

      // mutation 完了後に refetch が呼ばれ、クエリが2回以上実行されること
      await waitFor(() => {
        expect(mealFramesQueryInterceptor.mock.calls.length).toBeGreaterThanOrEqual(2);
      });
    });
  });
});
