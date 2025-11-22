import { gql } from '@apollo/client';
import * as z from 'zod';
import _ from 'lodash';
import {
  updateDishSchema,
  putDishRelationSchema,
  DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE,
  dishSourceRelationDetailOf,
  selectExistingDishSourceSchema,
  dishTagsSchema,
} from './schema';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../utils/mutationUtils';
import {
  EvaluateDishMutation,
  UpdateDishMutation,
  UpdateDishWithNewSourceMutation,
  useEvaluateDishMutation,
  useUpdateDishMutation,
  useUpdateDishWithNewSourceMutation,
} from '../../lib/graphql/generated/graphql';
import { newDishSourceSchema } from './source/schema';
import { normalizeDishSourceRelationDetail } from './normalizeFunctions';

export const UPDATE_DISH = gql`
  mutation updateDish(
    $dish: DishForUpdate!
    $dishSourceRelation: DishSourceRelationForUpdate
    $dishTags: [Tag!]
  ) {
    updateDish(input: {
      dish: $dish
      dishSourceRelation: $dishSourceRelation
      dishTags: $dishTags
    }
  ) {
      dishId
    }
  }
`;

const UpdateDishSchema = z.object({
  dish: updateDishSchema,
  selectedDishSource: selectExistingDishSourceSchema,
  dishSourceRelation: putDishRelationSchema,
  dishTags: dishTagsSchema,
});

export type UpdateDish = z.infer<typeof UpdateDishSchema>;

const convertFromUpdateDishInputToGraphqlInput = (
  input: UpdateDish,
): UpdateDish => {
  const normalizedInput = _.cloneDeep(input);
  const { dishSourceRelation, dish, selectedDishSource } = input;

  // TODO: UpdateDishWithNewSourceやAddDishとmutationエンドポイントの引数のスキーマ揃えて、共通メソッド使用

  const dishSourceRelationDetailType = dishSourceRelationDetailOf(
    selectedDishSource.type,
  );
  if (
    !dishSourceRelation ||
    !dishSourceRelation.dishSourceRelationDetail ||
    dishSourceRelationDetailType ===
      DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE.NO_VALUE
  ) {
    normalizedInput.dishSourceRelation = null;
    return normalizedInput;
  }

  delete normalizedInput.dishSourceRelation.dishSourceRelationDetail.detailType;
  normalizedInput.dishSourceRelation = {
    dishId: dish.id,
    dishSourceId: selectedDishSource.id,
    dishSourceType: selectedDishSource.type,
    dishSourceRelationDetail:
      normalizedInput.dishSourceRelation.dishSourceRelationDetail,
  };

  return normalizedInput;
};

export const UPDATE_DISH_WITH_NEW_SOURCE = gql`
  mutation updateDishWithNewSource(
    $dish: DishForUpdate!
    $dishSource: SourceForCreate!
    $dishSourceRelationDetail: DishSourceRelationDetail
    $dishTags: [Tag!]
  ) {
    updateDishWithNewSource(
      input: {
        dish: $dish
        dishSource: $dishSource
        dishSourceRelationDetail: $dishSourceRelationDetail
        dishTags: $dishTags
      }
    ) {
      dishId
    }
  }
`;

const UpdateDishWithNewSourceSchema = z.object({
  dish: updateDishSchema,
  dishSource: newDishSourceSchema,
  dishSourceRelation: putDishRelationSchema,
  dishTags: dishTagsSchema,
});

export type UpdateDishWithNewSource = z.infer<
  typeof UpdateDishWithNewSourceSchema
>;

const convertFromUpdateDishWithNewSourceInputToGraphqlInput = (
  input: UpdateDishWithNewSource,
): UpdateDishWithNewSource => {
  const normalizedInput = _.cloneDeep(input);
  const { dishSource } = input;

  normalizedInput.dishSourceRelationDetail = normalizeDishSourceRelationDetail(
    dishSource.type,
    normalizedInput.dishSourceRelation.dishSourceRelationDetail,
  );
  return normalizedInput;
};

export type UpdateDishInput = UpdateDishWithNewSource | UpdateDish;
export type UpdateDishOutput =
  | UpdateDishWithNewSourceMutation
  | UpdateDishMutation;
export type UpdateDishFunc = (
  input: UpdateDishInput,
  mutationCallbacks: MutationCallbacks<UpdateDishOutput>,
) => void;

// HACK: 数が増えたら、上述のUpdateDishをuseUpdateOnlyDishFieldsに移動
export const EVALUATE_DISH = gql`
  mutation evaluateDish($dishId: Int!, $score: Float!) {
    evaluateDish(input: { dishId: $dishId, score: $score }) {
      dishId
    }
  }
`;

export type EvaluateDish = {
  dishId: number;
  score: number;
};

export const useUpdateDish = () => {
  const [updateDish, updateDishLoading, updateDishError] =
    buildMutationExecutor<UpdateDish, UpdateDishMutation>(
      useUpdateDishMutation,
      { normalizeInput: convertFromUpdateDishInputToGraphqlInput },
    );

  const [
    updateDishWithNewSource,
    updateDishWithNewSourceLoading,
    updateDishWithNewSourceError,
  ] = buildMutationExecutor<
    UpdateDishWithNewSource,
    UpdateDishWithNewSourceMutation
  >(useUpdateDishWithNewSourceMutation, {
    normalizeInput: convertFromUpdateDishWithNewSourceInputToGraphqlInput,
  });

  const [evaluateDish, evaluateDishLoading, evaluateDishError] =
    buildMutationExecutor<EvaluateDish, EvaluateDishMutation>(
      useEvaluateDishMutation,
    );

  return {
    updateDish,
    UpdateDishSchema,

    updateDishWithNewSource,
    UpdateDishWithNewSourceSchema,

    evaluateDish,

    updateDishLoading:
      updateDishLoading ||
      updateDishWithNewSourceLoading ||
      evaluateDishLoading,
    updateDishError:
      updateDishError || updateDishWithNewSourceError || evaluateDishError,
  };
};
