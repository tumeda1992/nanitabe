'use client';

import React from 'react';
import {
  useForm,
  FormProvider,
  useFormContext,
  FieldError,
} from 'react-hook-form';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { zodResolver } from '@hookform/resolvers/zod';
import FormFieldWrapperWithLabel from '../../../common/form/FormFieldWrapperWithLabel';
import ErrorMessageIfExist from '../../../common/form/ErrorMessageIfExist';
import {
  DISH_SOURCE_TYPE,
  DISH_SOURCE_TYPE_LABELS,
  DISH_SOURCE_TYPES,
} from '../../../../features/dish/source/const';
import { DishSource } from '../../../../lib/graphql/generated/graphql';
import { AddOrUpdateDishSourceInput } from './types';

type DishSourceFormContentProps = {
  registeredDishSource?: DishSource;
};

export const DishSourceFormContent = (props: DishSourceFormContentProps) => {
  const { registeredDishSource } = props;
  const {
    register,
    formState: { errors },
  } = useFormContext<AddOrUpdateDishSourceInput>();

  return (
    <div>
      {/* <div className={style['reference-recipe']}> */}
      {/* <span className={style['reference-recipe__title']}> */}
      {/* 参考レシピ */}
      {/* </span> */}
      {registeredDishSource?.id && (
        <input
          type="hidden"
          value={registeredDishSource.id}
          {...register('dishSource.id', { valueAsNumber: true })}
        />
      )}
      <FormFieldWrapperWithLabel label="名前">
        <Input
          type="text"
          {...register('dishSource.name')}
          defaultValue={registeredDishSource?.name || ''}
          data-testid="dishSourceName"
        />
        <ErrorMessageIfExist errorMessage={errors.dishSource?.name?.message} />
      </FormFieldWrapperWithLabel>
      <FormFieldWrapperWithLabel label="タイプ">
        <select
          className="h-9 w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          defaultValue={registeredDishSource?.type || undefined}
          {...register('dishSource.type', { valueAsNumber: true })}
          data-testid="dishSourceTypeOption"
        >
          <option value={undefined} data-testid="dishSourceTypeOption-novalue">
            --
          </option>
          {DISH_SOURCE_TYPES.map((type) => (
            <option
              key={type}
              value={type}
              data-testid={`dishSourceTypeOption-${type}`}
            >
              {DISH_SOURCE_TYPE_LABELS[type]}
            </option>
          ))}
        </select>
        <ErrorMessageIfExist
          fieldError={errors.dishSource?.type as FieldError}
        />
      </FormFieldWrapperWithLabel>
    </div>
  );
};

type Props = {
  formSchema: any;
  onSubmit: any;

  registeredDishSource?: DishSource;

  onSchemaError?: any;
};
export default (props: Props) => {
  const { formSchema, onSubmit, onSchemaError, registeredDishSource } = props;

  const methods = useForm({ resolver: zodResolver(formSchema) });
  const { handleSubmit } = methods;

  const onError = (schemaErrors, _) => {
    if (onSchemaError) onSchemaError(schemaErrors);
  };

  return (
    <FormProvider {...methods}>
      <form onSubmit={handleSubmit(onSubmit, onError)}>
        <DishSourceFormContent registeredDishSource={registeredDishSource} />
        <div>
          <Button type="submit" data-testid="submitDishSourceButton">
            登録
          </Button>
        </div>
      </form>
    </FormProvider>
  );
};
