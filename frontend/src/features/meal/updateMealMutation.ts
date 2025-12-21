import { gql } from '@apollo/client';
import * as z from 'zod';
import _ from 'lodash';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../utils/mutationUtils';
import {
  UpdateMealMutation,
  UpdateMealWithNewDishAndNewSourceMutation,
  UpdateMealWithNewDishMutation,
  useUpdateMealMutation,
  useUpdateMealWithNewDishAndNewSourceMutation,
  useUpdateMealWithNewDishMutation,
} from '../../lib/graphql/generated/graphql';
import { dishIdSchema } from '../dish/schema';
import { updateMealSchema } from './schema';
import {
  AddDishSchema,
  AddDishWithNewSourceSchema,
} from '../dish/addDishMutation';
import {
  normalizeDishSourceRelationDetail,
  normalizeInputOfAddingDishWithExistingSource,
} from '../dish/normalizeFunctions';

export const UPDATE_MEAL = gql`
  mutation updateMeal($dishId: Int!, $meal: MealForUpdate!) {
    updateMeal(input: { dishId: $dishId, meal: $meal }) {
      mealId
    }
  }
`;

const UpdateMealSchema = z.object({
  dishId: dishIdSchema,
  meal: updateMealSchema,
});
export type UpdateMeal = z.infer<typeof UpdateMealSchema>;

export const UPDATE_MEAL_WITH_NEW_DISH = gql`
  mutation updateMealWithNewDish(
    $dish: DishForCreate!
    $dishSource: SourceForRead!
    $dishSourceRelationDetail: DishSourceRelationDetail
    $dishTags: [Tag!]
    $meal: MealForUpdate!
  ) {
    updateMealWithNewDish(
      input: {
        dish: $dish
        dishSource: $dishSource
        dishSourceRelationDetail: $dishSourceRelationDetail
        dishTags: $dishTags
        meal: $meal
      }
    ) {
      mealId
      dishId
    }
  }
`;

const UpdateMealWithNewDishSchema = AddDishSchema.extend({
  meal: updateMealSchema,
});
export type UpdateMealWithNewDish = z.infer<typeof UpdateMealWithNewDishSchema>;

const convertFromUpdateMealWithNewDishInputToGraphqlInput = (
  input: UpdateMealWithNewDish,
): UpdateMealWithNewDish => {
  const normalizedInput = _.cloneDeep(input);
  const { selectedDishSource } = input;

  return normalizeInputOfAddingDishWithExistingSource(
    normalizedInput,
    selectedDishSource,
    normalizedInput.dishSourceRelation.dishSourceRelationDetail,
  );
};

export const UPDATE_MEAL_WITH_NEW_DISH_AND_NEW_SOURCE = gql`
  mutation updateMealWithNewDishAndNewSource(
    $dish: DishForCreate!
    $dishSource: SourceForCreate!
    $dishSourceRelationDetail: DishSourceRelationDetail
    $dishTags: [Tag!]
    $meal: MealForUpdate!
  ) {
    updateMealWithNewDishAndNewSource(
      input: {
        dish: $dish
        dishSource: $dishSource
        dishSourceRelationDetail: $dishSourceRelationDetail
        dishTags: $dishTags
        meal: $meal
      }
    ) {
      mealId
      dishId
      dishSourceId
    }
  }
`;

const UpdateMealWithNewDishAndNewSourceSchema =
  AddDishWithNewSourceSchema.extend({
    meal: updateMealSchema,
  });
export type UpdateMealWithNewDishAndNewSource = z.infer<
  typeof UpdateMealWithNewDishAndNewSourceSchema
>;

const convertFromUpdateMealWithNewDishAndNewSourceInputToGraphqlInput = (
  input: UpdateMealWithNewDishAndNewSource,
): UpdateMealWithNewDishAndNewSource => {
  const normalizedInput = _.cloneDeep(input);
  const { dishSource } = input;

  normalizedInput.dishSourceRelationDetail = normalizeDishSourceRelationDetail(
    dishSource.type,
    normalizedInput.dishSourceRelation.dishSourceRelationDetail,
  );
  return normalizedInput;
};

export type UpdateMealInput =
  | UpdateMeal
  | UpdateMealWithNewDish
  | UpdateMealWithNewDishAndNewSource;
export type UpdateMealOutput =
  | UpdateMealMutation
  | UpdateMealWithNewDishMutation
  | UpdateMealWithNewDishAndNewSourceMutation;
export type UpdateMealFunc = (
  input: UpdateMealInput,
  mutationCallbacks: MutationCallbacks<UpdateMealOutput>,
) => void;

export const useUpdateMeal = () => {
  const [updateMeal, updateMealLoading, updateMealError] =
    buildMutationExecutor<UpdateMeal>(useUpdateMealMutation);

  const [
    updateMealWithNewDish,
    updateMealWithNewDishLoading,
    updateMealWithNewDishError,
  ] = buildMutationExecutor<UpdateMealWithNewDish>(
    useUpdateMealWithNewDishMutation,
    {
      normalizeInput: convertFromUpdateMealWithNewDishInputToGraphqlInput,
    },
  );

  const [
    updateMealWithNewDishAndNewSource,
    updateMealWithNewDishAndNewSourceLoading,
    updateMealWithNewDishAndNewSourceError,
  ] = buildMutationExecutor<UpdateMealWithNewDishAndNewSource>(
    useUpdateMealWithNewDishAndNewSourceMutation,
    {
      normalizeInput:
        convertFromUpdateMealWithNewDishAndNewSourceInputToGraphqlInput,
    },
  );

  return {
    updateMeal,
    UpdateMealSchema,

    updateMealWithNewDish,
    UpdateMealWithNewDishSchema,

    updateMealWithNewDishAndNewSource,
    UpdateMealWithNewDishAndNewSourceSchema,

    updateMealLoading:
      updateMealWithNewDishAndNewSourceLoading ||
      updateMealWithNewDishLoading ||
      updateMealLoading,
    updateMealError:
      updateMealWithNewDishAndNewSourceError ||
      updateMealWithNewDishError ||
      updateMealError,
  };
};
