import React, { useEffect, useState } from 'react';
import { Button, Form } from 'react-bootstrap';
import { FormProvider, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import style from '../MealForm.module.scss';
import FormFieldWrapperWithLabel from '../../../common/form/FormFieldWrapperWithLabel';
import { buildISODateString } from '../../../../features/utils/dateUtils';
import ErrorMessageIfExist from '../../../common/form/ErrorMessageIfExist';
import { MEAL_TYPE, MealType } from '../../../../features/meal/const';
import { DishFormContent } from '../../../dish/DishForm/DishForm';
import SelectMealType from './SelectMealType';
import { UseChoosingPutDishSourceTypeResult } from '../../../dish/DishForm/DishForm/useChoosingPutDishSourceType';
import {
  CHOOSING_DISH_TYPE,
  UseChoosingDishTypeResult,
} from './useChoosingDishType';
import { ExistingDishesForRegisteringWithMeal } from './ExistingDishesForRegisteringWithMeal';
import { AddOrUpdateMealInput } from './types';

type Props = {
  formSchema: any;
  onSubmit: any;

  defaultDate: Date;
  registeredMealId?: number;
  registeredMealType?: number;
  registeredDishId?: number;

  useChoosingDishTypeResult: UseChoosingDishTypeResult;
  useChoosingPutDishSourceTypeResult: UseChoosingPutDishSourceTypeResult;

  onSchemaError?: any;
};

export default (props: Props) => {
  const {
    formSchema,
    onSubmit,
    defaultDate,
    registeredMealId,
    registeredMealType,
    registeredDishId,
    useChoosingDishTypeResult: {
      setChoosingDishType,
      choosingRegisterNewDish,
      choosingUseExistingDish,
    },
    useChoosingPutDishSourceTypeResult,
    onSchemaError,
  } = props;

  const methods = useForm<AddOrUpdateMealInput>({
    resolver: zodResolver(formSchema),
  });

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset, // 使わないことに不都合があったらonDisplayとかを定義してuseEffect内で使用
    setValue,
  } = methods;

  const [selectedMealType, setSelectedMealType] = useState<MealType>(
    (registeredMealType as MealType) || MEAL_TYPE.DINNER,
  );
  useEffect(() => {
    setValue('meal.mealType', selectedMealType);
  }, [selectedMealType]);

  const onError = (schemaErrors, _) => {
    if (onSchemaError) onSchemaError(schemaErrors);
  };

  return (
    <div className={style['form']}>
      <FormProvider {...methods}>
        <Form onSubmit={handleSubmit(onSubmit, onError)}>
          {registeredMealId && (
            <input
              type="hidden"
              value={registeredMealId}
              {...register('meal.id', { valueAsNumber: true })}
            />
          )}
          <FormFieldWrapperWithLabel label="日付" required>
            <Form.Control
              type="date"
              defaultValue={buildISODateString(defaultDate)}
              {...register('meal.date', { valueAsDate: true })}
              data-testid="mealDate"
            />
            <ErrorMessageIfExist fieldError={errors.meal?.date} />
          </FormFieldWrapperWithLabel>

          <FormFieldWrapperWithLabel label="時間帯" required>
            <SelectMealType
              selectedMealType={selectedMealType as MealType}
              onChange={(mealType) => {
                setSelectedMealType(mealType);
              }}
            />
            <ErrorMessageIfExist fieldError={errors.meal?.mealType} />
          </FormFieldWrapperWithLabel>

          <div className={style['meal-form']}>
            <Form.Group>
              <Form.Check
                type="radio"
                inline
                name="add_meal_type"
                value={CHOOSING_DISH_TYPE.CHOOSING_USE_EXISTING_DISH}
                onChange={() =>
                  setChoosingDishType(
                    CHOOSING_DISH_TYPE.CHOOSING_USE_EXISTING_DISH,
                  )
                }
                checked={choosingUseExistingDish}
                label="料理を選択"
                id="optionOfUsingExistingDish"
                data-testid="optionOfUsingExistingDish"
              />
              <Form.Check
                type="radio"
                inline
                name="add_meal_type"
                value={CHOOSING_DISH_TYPE.CHOOSING_REGISTER_NEW_DISH}
                onChange={() =>
                  setChoosingDishType(
                    CHOOSING_DISH_TYPE.CHOOSING_REGISTER_NEW_DISH,
                  )
                }
                checked={choosingRegisterNewDish}
                label="新しく料理を登録"
                id="optionOfRegisteringNewDish"
                data-testid="optionOfRegisteringNewDish"
              />
            </Form.Group>

            {/*
              現在新規dish作成コンポーネントが使い回せるから使いまわしているが、
              デザインの都合・submitするフィールドの都合でmealフォーム都合の修正が必要になったら、
              それに合わせたコンポーネントを作る
             */}
            {choosingRegisterNewDish && (
              <DishFormContent
                useChoosingPutDishSourceTypeResult={
                  useChoosingPutDishSourceTypeResult
                }
              />
            )}

            {choosingUseExistingDish && (
              <ExistingDishesForRegisteringWithMeal
                dishIdRegisteredWithMeal={registeredDishId}
                displayNewDishIconForSelect
                onNewDishIconForSelectClick={(searchString) => {
                  setChoosingDishType(
                    CHOOSING_DISH_TYPE.CHOOSING_REGISTER_NEW_DISH,
                  );
                  setValue('dish.name', searchString);
                }}
              />
            )}
          </div>

          <Form.Group>
            <Button type="submit" data-testid="submitMealButton">
              登録
            </Button>
          </Form.Group>
        </Form>
      </FormProvider>
    </div>
  );
};
