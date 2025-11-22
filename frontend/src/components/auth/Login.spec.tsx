import React from 'react';
import '@testing-library/jest-dom';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MockedProvider } from '@apollo/client/testing';
import Login from './Login';
import { LoginDocument } from '../../lib/graphql/generated/graphql';
import renderWithApollo from '../specHelper/renderWithApollo';
import { enterTextBox } from '../specHelper/userEvents';
import { registerMutationHandler } from '../../lib/graphql/specHelper/mockServer';

const getLoginMessage = (screen) => screen.getByTestId('loginResultMessage');

const loginSucceededResult = {
  loginUserLogin: {
    credentials: {
      uid: 'hogehoge@gmail.com',
    },
  },
};

describe('<Login>', () => {
  describe('with MockedPrivider, ', () => {
    describe('when login with valid params, ', () => {
      beforeEach(() => {
        const validLoginMock = {
          request: {
            query: LoginDocument,
            variables: {
              email: 'hogehoge@gmail.com',
              password: 'hogehoge',
            },
          },
          result: {
            data: loginSucceededResult,
          },
        };
        render(
          <MockedProvider mocks={[validLoginMock]}>
            <Login />
          </MockedProvider>,
        );
      });

      it('succeeds', async () => {
        enterTextBox(screen, 'email', 'hogehoge@gmail.com');
        enterTextBox(screen, 'password', 'hogehoge');
        fireEvent.click(screen.getByTestId('loginButton'));

        await waitFor(() => getLoginMessage(screen));
        expect(getLoginMessage(screen)).toHaveTextContent(
          'ログインが成功しました',
        );
      });
    });
  });

  describe('with msw graqhql, ', () => {
    describe('when login with valid params, ', () => {
      it('succeeds with expected graphql params', async () => {
        const { getLatestMutationVariables } = registerMutationHandler(
          LoginDocument,
          loginSucceededResult,
        );
        renderWithApollo(<Login />);

        const email = 'hogehoge@gmail.com';
        enterTextBox(screen, 'email', email);
        const password = 'hogehoge';
        enterTextBox(screen, 'password', password);
        fireEvent.click(screen.getByTestId('loginButton'));

        await waitFor(() => getLoginMessage(screen));

        expect(getLatestMutationVariables()).toEqual({
          email,
          password,
        });
        expect(getLoginMessage(screen)).toHaveTextContent(
          'ログインが成功しました',
        );
      });
    });
  });
});
