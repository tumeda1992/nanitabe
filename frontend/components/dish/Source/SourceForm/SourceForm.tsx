import React from 'react';
import {
  useForm,
  FormProvider,
  useFormContext,
  FieldError,
} from 'react-hook-form';
import { Button, Form } from 'react-bootstrap';
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
        <Form.Control
          type="text"
          {...register('dishSource.name')}
          defaultValue={registeredDishSource?.name || ''}
          data-testid="dishSourceName"
        />
        <ErrorMessageIfExist errorMessage={errors.dishSource?.name?.message} />
      </FormFieldWrapperWithLabel>
      <FormFieldWrapperWithLabel label="タイプ">
        <Form.Select
          defaultValue={
            // 本当は初期値を設定したいけど、新規食事登録時に変更を挟まないとwatchで検知できないから仕方なく選ばせる
            // registeredDishSource?.type || DISH_SOURCE_TYPE.RECIPE_BOOK
            registeredDishSource?.type || null
          }
          {...register('dishSource.type', { valueAsNumber: true })}
          data-testid="dishSourceTypeOption"
        >
          <option value={null} data-testid="dishSourceTypeOption-novalue">
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
        </Form.Select>
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
      <Form onSubmit={handleSubmit(onSubmit, onError)}>
        <DishSourceFormContent registeredDishSource={registeredDishSource} />
        <Form.Group>
          <Button type="submit" data-testid="submitDishSourceButton">
            登録
          </Button>
        </Form.Group>
      </Form>
    </FormProvider>
  );
};
