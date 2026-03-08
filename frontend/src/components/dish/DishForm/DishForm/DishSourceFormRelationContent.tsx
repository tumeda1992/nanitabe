import { useFormContext } from 'react-hook-form';
import React, { useEffect, useState } from 'react';
import { Input } from '@/components/ui/input';
import {
  DISH_SOURCE_TYPE,
  DISH_SOURCE_TYPES,
  DishSourceType,
} from '../../../../features/dish/source/const';
import FormFieldWrapperWithLabel from '../../../common/form/FormFieldWrapperWithLabel';
import ErrorMessageIfExist from '../../../common/form/ErrorMessageIfExist';
import {
  DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE,
  dishSourceRelationDetailOf,
} from '../../../../features/dish/schema';
import { DishSourceRelation } from '../../../../lib/graphql/generated/graphql';
import { AddOrUpdateDishInput } from './types';

const defaultDishSourceRelation = {
  recipeBookPage: null,
  recipeWebsiteUrl: '',
  recipeSourceMemo: '',
};

type DishSourceFormRelationContentProps = {
  dishSourceType: DishSourceType | null;
  dishSourceRelation: DishSourceRelation | null;
};

export const DishSourceFormRelationContent = (
  props: DishSourceFormRelationContentProps,
) => {
  const { dishSourceType, dishSourceRelation: dishSourceRelationFromProps } =
    props;

  const {
    register,
    formState: { errors },
  } = useFormContext<AddOrUpdateDishInput>();

  const [dishSourceRelation, setDishSourceRelation] =
    useState<DishSourceRelation>(() => {
      return (dishSourceRelationFromProps ??
        defaultDishSourceRelation) as DishSourceRelation;
    });

  const editDishSourceRelationDetail = (params: {
    recipeBookPage?: number | null;
    recipeWebsiteUrl?: string;
    recipeSourceMemo?: string;
  }) => {
    setDishSourceRelation((prev) => ({
      ...prev,
      ...params,
    }));
  };

  const detailType = dishSourceRelationDetailOf(dishSourceType);

  return (
    <>
      <input
        type="hidden"
        value={detailType}
        {...register('dishSourceRelation.dishSourceRelationDetail.detailType')}
      />
      {detailType ===
        DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE.RECIPE_BOOK_PAGE && (
        <FormFieldWrapperWithLabel label="ページ数">
          <Input
            type="number"
            {...register(
              'dishSourceRelation.dishSourceRelationDetail.recipeBookPage',
              { valueAsNumber: true },
            )}
            value={dishSourceRelation.recipeBookPage || ''}
            onChange={(e) => {
              const enteredValue = e.target.value;
              const page = Number.isNaN(enteredValue)
                ? null
                : Number(enteredValue);
              editDishSourceRelationDetail({
                recipeBookPage: page,
              });
            }}
            data-testid="dishSourceRelationDetailRecipeBookPage"
          />
          <ErrorMessageIfExist
            errorMessage={
              errors.dishSourceRelation?.dishSourceRelationDetail
                ?.recipeBookPage
            }
          />
        </FormFieldWrapperWithLabel>
      )}
      {detailType ===
        DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE.RECIPE_WEBSITE_URL && (
        <FormFieldWrapperWithLabel label="レシピURL">
          <Input
            type="text"
            {...register(
              'dishSourceRelation.dishSourceRelationDetail.recipeWebsiteUrl',
            )}
            value={dishSourceRelation.recipeWebsiteUrl || ''}
            onChange={(e) => {
              editDishSourceRelationDetail({
                recipeWebsiteUrl: e.target.value,
              });
            }}
            data-testid="dishSourceRelationDetailRecipeWebsiteUrl"
          />
          <ErrorMessageIfExist
            errorMessage={
              errors.dishSourceRelation?.dishSourceRelationDetail
                ?.recipeWebsiteUrl
            }
          />
        </FormFieldWrapperWithLabel>
      )}
      {detailType ===
        DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE.RECIPE_SOURCE_MEMO && (
        <FormFieldWrapperWithLabel label="メモ">
          <Input
            type="text"
            {...register(
              'dishSourceRelation.dishSourceRelationDetail.recipeSourceMemo',
            )}
            value={dishSourceRelation.recipeSourceMemo || ''}
            onChange={(e) => {
              editDishSourceRelationDetail({
                recipeSourceMemo: e.target.value,
              });
            }}
            data-testid="dishSourceRelationDetailRecipeSourceMemo"
          />
          <ErrorMessageIfExist
            errorMessage={
              errors.dishSourceRelation?.dishSourceRelationDetail
                ?.recipeSourceMemo
            }
          />
        </FormFieldWrapperWithLabel>
      )}
    </>
  );
};
