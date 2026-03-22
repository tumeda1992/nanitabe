import React from 'react';
import '@testing-library/jest-dom';
import { screen, fireEvent, waitFor } from '@testing-library/react';
import { FormProvider, useForm } from 'react-hook-form';
import { render } from '@testing-library/react';
import { ApolloClient, InMemoryCache } from '@apollo/client';
import { HttpLink } from '@apollo/client/link/http';
import { ApolloProvider } from '@apollo/client/react';
import fetch from 'isomorphic-unfetch';
import {
  registerQueryHandler,
} from '../../../../lib/graphql/specHelper/mockServer';
import { DishEffortLevelsDocument } from '../../../../lib/graphql/generated/graphql';
import SelectEffortLevel from './SelectEffortLevel';

const createClient = () =>
  new ApolloClient({
    ssrMode: false,
    link: new HttpLink({ uri: 'http://localhost', credentials: 'same-origin', fetch }),
    cache: new InMemoryCache(),
  });

const renderWithProviders = (component: React.ReactNode, onSubmit?: (data: any) => void) => {
  const Wrapper = () => {
    const methods = useForm({ defaultValues: { dish: { dishEffortLevelId: null } } });
    return (
      <ApolloProvider client={createClient()}>
        <FormProvider {...methods}>
          <form onSubmit={methods.handleSubmit((data) => { if (onSubmit) onSubmit(data); })}>
            {component}
            <button type="submit" data-testid="submitBtn">送信</button>
          </form>
        </FormProvider>
      </ApolloProvider>
    );
  };
  return render(<Wrapper />);
};

const effortLevels = [
  { __typename: 'DishEffortLevel' as const, id: 1, minutes: 10, label: 'ぱぱっとできる' },
  { __typename: 'DishEffortLevel' as const, id: 2, minutes: 20, label: '普通' },
];

describe('<SelectEffortLevel>', () => {
  describe('mealPositionに応じた選択肢が表示される', () => {
    beforeEach(() => {
      registerQueryHandler(DishEffortLevelsDocument, {
        dishEffortLevels: effortLevels,
      });
    });

    it('手間レベルの選択肢が表示されること', async () => {
      renderWithProviders(<SelectEffortLevel mealPosition={1} />);

      expect(await screen.findByText('10分 - ぱぱっとできる')).toBeInTheDocument();
      expect(screen.getByText('20分 - 普通')).toBeInTheDocument();
    });

    it('60分以上は時間表記になること', async () => {
      registerQueryHandler(DishEffortLevelsDocument, {
        dishEffortLevels: [
          { __typename: 'DishEffortLevel' as const, id: 3, minutes: 150, label: '結構手間' },
          { __typename: 'DishEffortLevel' as const, id: 4, minutes: 480, label: 'かなり手間' },
        ],
      });
      renderWithProviders(<SelectEffortLevel mealPosition={1} />);

      expect(await screen.findByText('2時間30分 - 結構手間')).toBeInTheDocument();
      expect(screen.getByText('8時間 - かなり手間')).toBeInTheDocument();
    });

    it('選択なし選択肢が含まれること', async () => {
      renderWithProviders(<SelectEffortLevel mealPosition={1} />);

      expect(await screen.findByText('指定なし')).toBeInTheDocument();
    });
  });

  describe('手間未選択で submit できること', () => {
    it('手間未選択（空文字）のとき dishEffortLevelId が null として送信されること', async () => {
      registerQueryHandler(DishEffortLevelsDocument, {
        dishEffortLevels: effortLevels,
      });

      const onSubmit = jest.fn();
      renderWithProviders(<SelectEffortLevel mealPosition={1} />, onSubmit);

      await screen.findByText('指定なし');

      // 「指定なし」（空文字）が選択された状態でsubmit
      fireEvent.change(screen.getByTestId('dishEffortLevelSelect'), { target: { value: '' } });
      fireEvent.click(screen.getByTestId('submitBtn'));

      await waitFor(() => expect(onSubmit).toHaveBeenCalledTimes(1));
      expect(onSubmit.mock.calls[0][0].dish.dishEffortLevelId).toBeNull();
    });
  });
});
