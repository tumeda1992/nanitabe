import React from 'react';
import { SubmitHandler } from 'react-hook-form';
import useDishSource from '../../../../features/dish/source/useDishSource';
import type {
  AddDishSource,
  UpdateDishSource,
} from '../../../../features/dish/source/useDishSource';
import SourceForm from './SourceForm';
import { DishSource } from '../../../../lib/graphql/generated/graphql';

type Props = {
  dishSource: DishSource;
  onEditSucceeded?: () => void;
  onSchemaError?: any;
};

export default (props: Props) => {
  const { onEditSucceeded, onSchemaError, dishSource } = props;

  const { updateDishSource, UpdateDishSourceSchema } = useDishSource();
  const onSubmit: SubmitHandler<UpdateDishSource> = async (input) => {
    await updateDishSource(input, {
      onCompleted: (_) => {
        if (onEditSucceeded) onEditSucceeded();
      },
    });
  };

  return (
    <SourceForm
      onSubmit={onSubmit}
      formSchema={UpdateDishSourceSchema}
      onSchemaError={onSchemaError}
      registeredDishSource={dishSource}
    />
  );
};
