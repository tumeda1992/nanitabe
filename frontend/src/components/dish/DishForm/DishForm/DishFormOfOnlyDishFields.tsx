import { useFormContext } from 'react-hook-form';
import { Input } from '@/components/ui/input';
import React, { useEffect, useState } from 'react';
import { Dish } from '../../../../lib/graphql/generated/graphql';
import FormFieldWrapperWithLabel from '../../../common/form/FormFieldWrapperWithLabel';
import ErrorMessageIfExist from '../../../common/form/ErrorMessageIfExist';
import { MEAL_POSITION, MealPosition } from '../../../../features/dish/const';
import SelectMealPosition from './SelectMealPosition';
import SelectEffortLevel from './SelectEffortLevel';
import { AddOrUpdateDishInput } from './types';

const MEAL_POSITIONS_WITH_EFFORT_LEVEL = [
  MEAL_POSITION.STAPLE_FOOD,
  MEAL_POSITION.MAIN_DISH,
  MEAL_POSITION.SIDE_DISH,
];

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
    setValue('dish.dishEffortLevelId', null);
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
        <Input
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
            if (!mealPosition) return;
            setSelectedMealPosition(mealPosition);
          }}
        />
        <ErrorMessageIfExist
          errorMessage={errors.dish?.mealPosition?.message}
        />
      </FormFieldWrapperWithLabel>
      {MEAL_POSITIONS_WITH_EFFORT_LEVEL.includes(selectedMealPosition) && (
        <FormFieldWrapperWithLabel label="手間">
          <SelectEffortLevel mealPosition={selectedMealPosition} />
        </FormFieldWrapperWithLabel>
      )}
      <FormFieldWrapperWithLabel label="コメント">
        <textarea
          className="flex w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
          {...register('dish.comment')}
          rows={1}
          defaultValue={preFilledDish?.comment || ''}
          placeholder="料理のメモや感想を入力..."
          data-testid="dishComment"
        />
        <ErrorMessageIfExist errorMessage={errors.dish?.comment?.message} />
      </FormFieldWrapperWithLabel>
    </>
  );
};
