import { gql } from '@apollo/client';
import * as z from 'zod';
import {
  useLoginMutation,
  LoginMutation,
} from '../../lib/graphql/generated/graphql';

export const LOGIN = gql`
  mutation login($email: String!, $password: String!) {
    loginUserLogin(email: $email, password: $password) {
      credentials {
        uid
      }
    }
  }
`;

const LoginSchema = z.object({
  email: z.string().min(1, { message: '必須項目です。' }),
  password: z.string().min(1, { message: '必須項目です。' }),
});
export type LoginInput = z.infer<typeof LoginSchema>;
export type Login = Required<LoginInput>;

export const useLogin = () => {
  const [loginMutation, { loading: loginLoading, error: loginError }] =
    useLoginMutation();
  const login = async (input: Login, { onCompleted, onError }) => {
    return loginMutation({
      variables: input,
      onCompleted: async (data: LoginMutation) => {
        // 認証情報はApolloClientでレスポンスヘッダからCookieに詰めている
        onCompleted();
      },
      onError: async (error) => {
        onError(error);
      },
    });
  };
  return {
    login,
    loginLoading,
    loginError,
    LoginSchema,
  };
};
