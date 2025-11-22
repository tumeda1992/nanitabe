import { useFormContext } from 'react-hook-form';
import { Form } from 'react-bootstrap';
import React, { useEffect, useState } from 'react';
import { Dish } from '../../../../lib/graphql/generated/graphql';
import FormFieldWrapperWithLabel from '../../../common/form/FormFieldWrapperWithLabel';
import ErrorMessageIfExist from '../../../common/form/ErrorMessageIfExist';
import { MEAL_POSITION, MealPosition } from '../../../../features/dish/const';
import SelectMealPosition from './SelectMealPosition';
import { AddOrUpdateDishInput } from './types';

type DishFormOfOnlyDishFieldsProps = {
  preFilledDish?: Dish;
};
export const DishFormOfOnlyDishFields = (
  props: DishFormOfOnlyDishFieldsProps,
) => {
  const { preFilledDish } = props;

  const {
    register,
    formState: { errors },
    setValue,
  } = useFormContext<AddOrUpdateDishInput>();

  const [selectedMealPosition, setSelectedMealPosition] =
    useState<MealPosition>(
      (preFilledDish?.mealPosition as MealPosition) || MEAL_POSITION.MAIN_DISH,
    );
  useEffect(() => {
    setValue('dish.mealPosition', selectedMealPosition);
  }, [selectedMealPosition]);

  return (
    <>
      {preFilledDish?.id && (
        <input
          type="hidden"
          value={preFilledDish.id}
          {...register('dish.id', { valueAsNumber: true })}
        />
      )}
      <FormFieldWrapperWithLabel label="料理名" required>
        <Form.Control
          type="text"
          {...register('dish.name')}
          defaultValue={preFilledDish?.name}
          data-testid="dishname"
        />
        <ErrorMessageIfExist errorMessage={errors.dish?.name?.message} />
      </FormFieldWrapperWithLabel>
      <FormFieldWrapperWithLabel label="位置づけ">
        <SelectMealPosition
          selectedMealPosition={selectedMealPosition as MealPosition}
          onChange={(mealPosition) => {
            setSelectedMealPosition(mealPosition);
          }}
        />
        <ErrorMessageIfExist
          errorMessage={errors.dish?.mealPosition?.message}
        />
      </FormFieldWrapperWithLabel>
    </>
  );
};
