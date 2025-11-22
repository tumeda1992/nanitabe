import { gql } from '@apollo/client';
import * as z from 'zod';
import _ from 'lodash';
import {
  AddMealMutation,
  AddMealWithNewDishAndNewSourceMutation,
  AddMealWithNewDishMutation,
  useAddMealMutation,
  useAddMealWithNewDishAndNewSourceMutation,
  useAddMealWithNewDishMutation,
} from '../../lib/graphql/generated/graphql';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../utils/mutationUtils';
import { newMealSchema } from './schema';
import { dishIdSchema, newDishSchema } from '../dish/schema';
import {
  normalizeDishSourceRelationDetail,
  normalizeInputOfAddingDishWithExistingSource,
} from '../dish/normalizeFunctions';
import {
  AddDishSchema,
  AddDishWithNewSourceSchema,
} from '../dish/addDishMutation';

export const ADD_MEAL = gql`
  mutation addMeal($dishId: Int!, $meal: MealForCreate!) {
    addMeal(input: { dishId: $dishId, meal: $meal }) {
      mealId
    }
  }
`;

const AddMealSchema = z.object({
  dishId: dishIdSchema,
  meal: newMealSchema,
});
export type AddMeal = z.infer<typeof AddMealSchema>;

export const ADD_MEAL_WITH_NEW_DISH = gql`
  mutation addMealWithNewDish(
    $dish: DishForCreate!
    $dishSource: SourceForRead
    $dishSourceRelationDetail: DishSourceRelationDetail
    $dishTags: [Tag!]
    $meal: MealForCreate!
  ) {
    addMealWithNewDish(
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

const AddMealWithNewDishSchema = AddDishSchema.extend({
  meal: newMealSchema,
});
export type AddMealWithNewDish = z.infer<typeof AddMealWithNewDishSchema>;

const convertFromAddMealWithNewDishInputToGraphqlInput = (
  input: AddMealWithNewDish,
): AddMealWithNewDish => {
  const normalizedInput = _.cloneDeep(input);
  const { selectedDishSource } = input;

  return normalizeInputOfAddingDishWithExistingSource(
    normalizedInput,
    selectedDishSource,
    normalizedInput.dishSourceRelation.dishSourceRelationDetail,
  );
};

export const ADD_MEAL_WITH_NEW_DISH_AND_NEW_SOURCE = gql`
  mutation addMealWithNewDishAndNewSource(
    $dish: DishForCreate!
    $dishSource: SourceForCreate!
    $dishSourceRelationDetail: DishSourceRelationDetail
    $dishTags: [Tag!]
    $meal: MealForCreate!
  ) {
    addMealWithNewDishAndNewSource(
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

const AddMealWithNewDishAndNewSourceSchema = AddDishWithNewSourceSchema.extend({
  meal: newMealSchema,
});
export type AddMealWithNewDishAndNewSource = z.infer<
  typeof AddMealWithNewDishAndNewSourceSchema
>;

const convertFromAddMealWithNewDishAndNewSourceInputToGraphqlInput = (
  input: AddMealWithNewDishAndNewSource,
): AddMealWithNewDishAndNewSource => {
  const normalizedInput = _.cloneDeep(input);
  const { dishSource } = input;

  normalizedInput.dishSourceRelationDetail = normalizeDishSourceRelationDetail(
    dishSource.type,
    normalizedInput.dishSourceRelation.dishSourceRelationDetail,
  );
  return normalizedInput;
};

export type AddMealMutationInput =
  | AddMeal
  | AddMealWithNewDish
  | AddMealWithNewDishAndNewSource;

export type AddMealMutationOutput =
  | AddMealWithNewDishAndNewSourceMutation
  | AddMealMutation
  | AddMealWithNewDishMutation;

export type AddMealFunc = (
  input: AddMealMutationInput,
  mutationCallbacks: MutationCallbacks<AddMealMutationOutput>,
) => void;

export const useAddMeal = () => {
  const [addMeal, addMealLoading, addMealError] = buildMutationExecutor<
    AddMeal,
    AddMealMutation
  >(useAddMealMutation);

  const [
    addMealWithNewDish,
    addMealWithNewDishLoading,
    addMealWithNewDishError,
  ] = buildMutationExecutor<AddMealWithNewDish, AddMealWithNewDishMutation>(
    useAddMealWithNewDishMutation,
    {
      normalizeInput: convertFromAddMealWithNewDishInputToGraphqlInput,
    },
  );

  const [
    addMealWithNewDishAndNewSource,
    addMealWithNewDishAndNewSourceLoading,
    addMealWithNewDishAndNewSourceError,
  ] = buildMutationExecutor<
    AddMealWithNewDishAndNewSource,
    AddMealWithNewDishAndNewSourceMutation
  >(useAddMealWithNewDishAndNewSourceMutation, {
    normalizeInput:
      convertFromAddMealWithNewDishAndNewSourceInputToGraphqlInput,
  });

  return {
    addMeal,
    AddMealSchema,

    addMealWithNewDish,
    AddMealWithNewDishSchema,

    addMealWithNewDishAndNewSource,
    AddMealWithNewDishAndNewSourceSchema,

    addMealLoading:
      addMealWithNewDishAndNewSourceLoading ||
      addMealLoading ||
      addMealWithNewDishLoading,
    addMealError:
      addMealWithNewDishAndNewSourceError ||
      addMealError ||
      addMealWithNewDishError,
  };
};
