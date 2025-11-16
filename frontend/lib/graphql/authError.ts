import { GraphQLError } from 'graphql';
import { useReactiveVar } from '@apollo/client/react';
import { useEffect } from 'react';
import { apiErrors } from './globalVars';

const AUTHENTICATION_ERROR_CODE = 'AUTHENTICATION_ERROR';

const isAuthenticationError = (error) => {
  const graphqlError = error as GraphQLError;
  return graphqlError?.extensions?.code === AUTHENTICATION_ERROR_CODE;
};

export const useAuthErrorHandle = (funcOnAuthErrorOccurred: () => void) => {
  const errors = useReactiveVar(apiErrors);
  useEffect(() => {
    if (errors.some((error) => isAuthenticationError(error))) {
      apiErrors([]);
      funcOnAuthErrorOccurred();
    }
  }, [errors]);
};
