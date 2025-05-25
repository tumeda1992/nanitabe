import React from 'react';
import { FieldError } from 'react-hook-form';

type Props = {
  errorMessage?: string | FieldError;
};

export default (props: Props) => {
  const { errorMessage } = props;
  if (!errorMessage) return null;

  return <p>{errorMessage.toString()}</p>;
};
