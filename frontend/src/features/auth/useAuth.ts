import { useSignup } from './signUpMutation';
import { useLogin } from './loginMutation';

export type { Signup } from './signUpMutation';
export type { Login } from './loginMutation';

export default () => {
  const { signup, signupLoading, signupError, SignupSchema } = useSignup();
  const { login, loginLoading, loginError, LoginSchema } = useLogin();

  return {
    signup,
    signupLoading,
    signupError,
    SignupSchema,
    login,
    loginLoading,
    loginError,
    LoginSchema,
  };
};
