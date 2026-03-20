import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
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

const renderWithProviders = (component: React.ReactNode) => {
  const Wrapper = () => {
    const methods = useForm({ defaultValues: { dish: { dishEffortLevelId: null } } });
    return (
      <ApolloProvider client={createClient()}>
        <FormProvider {...methods}>
          {component}
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

    it('選択なし選択肢が含まれること', async () => {
      renderWithProviders(<SelectEffortLevel mealPosition={1} />);

      expect(await screen.findByText('指定なし')).toBeInTheDocument();
    });
  });
});
