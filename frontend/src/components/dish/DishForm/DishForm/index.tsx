import React from 'react';
import { FormProvider, useForm } from 'react-hook-form';
import { Button, Form } from 'react-bootstrap';
import { zodResolver } from '@hookform/resolvers/zod';
import { Dish } from '../../../../lib/graphql/generated/graphql';
import { DishFormOfOnlyDishFields } from './DishFormOfOnlyDishFields';
import { UseChoosingPutDishSourceTypeResult } from './useChoosingPutDishSourceType';
import { DishFormOfRelatedDishSource } from './DishFormOfRelatedDishSource';
import { DishFormOfTags } from './DishFormOfTags';

type DishFormContentProps = {
  preFilledDish?: Dish;
  useChoosingPutDishSourceTypeResult: UseChoosingPutDishSourceTypeResult;
};

export const DishFormContent = (props: DishFormContentProps) => {
  const { preFilledDish, useChoosingPutDishSourceTypeResult } = props;

  return (
    <>
      <DishFormOfOnlyDishFields preFilledDish={preFilledDish} />
      <DishFormOfRelatedDishSource
        preFilledDish={preFilledDish}
        useChoosingPutDishSourceTypeResult={useChoosingPutDishSourceTypeResult}
      />
      <DishFormOfTags preFilledDish={preFilledDish} />
    </>
  );
};

type Props = {
  formSchema: any;
  onSubmit: any;
  children?: React.ReactNode;

  preFilledDish?: Dish;

  useChoosingPutDishSourceTypeResult: UseChoosingPutDishSourceTypeResult;

  onSchemaError?: any;
  doContinuousRegistration?: any;
  toggleDoContinuousRegistration?: any;
};

export default (props: Props) => {
  const {
    formSchema,
    onSubmit,
    preFilledDish,
    onSchemaError,
    children,
    useChoosingPutDishSourceTypeResult,
    doContinuousRegistration,
    toggleDoContinuousRegistration,
  } = props;

  const methods = useForm({ resolver: zodResolver(formSchema) });
  const { handleSubmit } = methods;

  const onError = (schemaErrors, _) => {
    if (onSchemaError) onSchemaError(schemaErrors);
  };

  return (
    <FormProvider {...methods}>
      <Form onSubmit={handleSubmit(onSubmit, onError)}>
        <DishFormContent
          preFilledDish={preFilledDish}
          useChoosingPutDishSourceTypeResult={
            useChoosingPutDishSourceTypeResult
          }
        />
        {children}

        {doContinuousRegistration !== undefined && (
          <div>
            {/* デザインちゃんとする */}
            <input
              type="checkbox"
              id="continuousRegistrationCheck"
              data-testid="continuousRegistrationCheck"
              checked={doContinuousRegistration}
              onChange={() => toggleDoContinuousRegistration()}
            />
            <label htmlFor="continuousRegistrationCheck">連続登録する</label>
          </div>
        )}
        <Form.Group>
          <Button type="submit" data-testid="submitDishButton">
            登録
          </Button>
        </Form.Group>
      </Form>
    </FormProvider>
  );
};
