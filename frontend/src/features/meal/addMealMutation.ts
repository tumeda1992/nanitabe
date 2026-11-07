import {
  normalizeDishInputWithExistingSource,
  normalizeDishInputWithNewSource,
} from '../dish/normalizeFunctions';
import { gql } from '@apollo/client';
import * as z from 'zod';
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
  AddDishSchema,
  AddDishWithNewSourceSchema,
} from '../dish/addDishMutation';

export const ADD_MEAL = gql`
  mutation addMeal($dishId: Int!, $meal: MealForCreate!, $frameEntryId: Int) {
    addMeal(
      input: { dishId: $dishId, meal: $meal, frameEntryId: $frameEntryId }
    ) {
      mealId
    }
  }
`;

const AddMealSchema = z.object({
  dishId: dishIdSchema,
  meal: newMealSchema,
  frameEntryId: z.number().optional(),
});
export type AddMeal = z.infer<typeof AddMealSchema>;

export const ADD_MEAL_WITH_NEW_DISH = gql`
  mutation addMealWithNewDish(
    $dish: DishForCreate!
    $dishSource: SourceForRead
    $dishSourceRelationDetail: DishSourceRelationDetail
    $dishTags: [Tag!]
    $meal: MealForCreate!
    $frameEntryId: Int
  ) {
    addMealWithNewDish(
      input: {
        dish: $dish
        dishSource: $dishSource
        dishSourceRelationDetail: $dishSourceRelationDetail
        dishTags: $dishTags
        meal: $meal
        frameEntryId: $frameEntryId
      }
    ) {
      mealId
      dishId
    }
  }
`;

const AddMealWithNewDishSchema = AddDishSchema.extend({
  meal: newMealSchema,
  frameEntryId: z.number().optional(),
});
export type AddMealWithNewDish = z.infer<typeof AddMealWithNewDishSchema>;

const convertFromAddMealWithNewDishInputToGraphqlInput =
  normalizeDishInputWithExistingSource<AddMealWithNewDish>;

export const ADD_MEAL_WITH_NEW_DISH_AND_NEW_SOURCE = gql`
  mutation addMealWithNewDishAndNewSource(
    $dish: DishForCreate!
    $dishSource: SourceForCreate!
    $dishSourceRelationDetail: DishSourceRelationDetail
    $dishTags: [Tag!]
    $meal: MealForCreate!
    $frameEntryId: Int
  ) {
    addMealWithNewDishAndNewSource(
      input: {
        dish: $dish
        dishSource: $dishSource
        dishSourceRelationDetail: $dishSourceRelationDetail
        dishTags: $dishTags
        meal: $meal
        frameEntryId: $frameEntryId
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
  frameEntryId: z.number().optional(),
});
export type AddMealWithNewDishAndNewSource = z.infer<
  typeof AddMealWithNewDishAndNewSourceSchema
>;

const convertFromAddMealWithNewDishAndNewSourceInputToGraphqlInput =
  normalizeDishInputWithNewSource<AddMealWithNewDishAndNewSource>;

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
