import React from 'react';
import { FieldError } from 'react-hook-form';

// TODO: 確定したらどちらかに寄せる
type Props = {
  errorMessage?: string | FieldError;
  fieldError?: FieldError;
};

export default (props: Props) => {
  const { errorMessage: errorMessageFromProp, fieldError } = props;

  const errorMessage = (() => {
    if (errorMessageFromProp) return errorMessageFromProp;
    if (fieldError) return fieldError.message;
    return null;
  })();
  if (!errorMessage) return null;

  return <p>{errorMessage.toString()}</p>;
};
