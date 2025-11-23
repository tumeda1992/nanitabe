import React from 'react';
import * as z from 'zod';
import { SubmitHandler } from 'react-hook-form';
import useDishSource from '../../../../features/dish/source/useDishSource';
import type { AddDishSource } from '../../../../features/dish/source/useDishSource';
import SourceForm from './SourceForm';

type Props = {
  onAddSucceeded?: () => void;
  onSchemaError?: any;
};

export default (props: Props) => {
  const { onAddSucceeded, onSchemaError } = props;

  const { addDishSource, AddDishSourceSchema } = useDishSource();
  const onSubmit: SubmitHandler<AddDishSource> = async (input) => {
    await addDishSource(input, {
      onCompleted: (_) => {
        if (onAddSucceeded) onAddSucceeded();
      },
    });
  };

  return (
    <SourceForm
      onSubmit={onSubmit}
      formSchema={AddDishSourceSchema}
      onSchemaError={onSchemaError}
    />
  );
};
